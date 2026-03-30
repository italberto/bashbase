# shellcheck shell=bash
# procesu.sh - Funções para gerenciamento de processos e controle de execução simultânea
#
# Fornece utilitários para verificar, encerrar e aguardar processos,
# além de mecanismo de lock para evitar execuções paralelas de um mesmo script.
#
# Quando DRYRUN="1":
#   matar_processo  - imprime o que seria feito sem enviar sinais
#   lock_adquirir   - simula aquisição bem-sucedida sem criar diretório/arquivo
#   lock_liberar    - simula liberação sem deletar nada
#
# Dependências: systemu.sh, sinais.sh, dryrun.sh
#
# Funções disponíveis:
#   e_processo_rodando        <nome>                  - Verifica se um processo está ativo pelo nome
#   matar_processo            <nome> [timeout]        - Encerra processo com fallback SIGTERM → SIGKILL
#   lock_adquirir             <lock>                  - Cria lock para execução exclusiva
#   lock_liberar              <lock>                  - Remove o arquivo de lock
#   lock_adquirir_com_cleanup <lock>                  - Adquire lock e registra liberação automática
#   aguardar_processo         <nome_ou_pid> [timeout] - Espera um processo terminar


[[ -n "${_PROCESU_SH_LOADED:-}" ]] && return 0
readonly _PROCESU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/systemu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/sinais.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function e_processo_rodando() {
    # Verifica se um processo está em execução pelo nome exato.
    # Retorna 0 se estiver rodando, 1 caso contrário.
    # Modo de uso: e_processo_rodando "nginx" && echo "nginx ativo"
    pgrep -x "$1" > /dev/null 2>&1
}

function matar_processo() {
    # Encerra todos os processos com o nome informado.
    # Envia SIGTERM primeiro e aguarda até <timeout> segundos.
    # Se o processo não terminar, envia SIGKILL.
    # Modo de uso: matar_processo "meu_script" 10
    local nome="$1"
    local timeout="${2:-5}"

    local pids
    pids=$(pgrep -x "$nome" 2>/dev/null)

    if [ -z "$pids" ]; then
        return 1
    fi

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] matar_processo: SIGTERM/SIGKILL → '$nome' (PIDs: $pids)" >&2
        return 0
    fi

    # Envia SIGTERM para encerramento gracioso
    kill "$pids" 2>/dev/null

    local contador=0
    while kill -0 "$pids" 2>/dev/null && [ "$contador" -lt "$timeout" ]; do
        sleep 1
        (( contador++ ))
    done

    # Se ainda estiver rodando após o timeout, força com SIGKILL
    if kill -0 "$pids" 2>/dev/null; then
        kill -9 "$pids" 2>/dev/null
    fi

    return 0
}

function lock_adquirir() {
    # Adquire um lock de execução exclusiva usando um diretório como sentinela.
    # mkdir é uma operação atômica no kernel, eliminando a race condition entre
    # verificar e criar que existe com arquivos comuns.
    # O PID do processo dono é gravado em <lock>/pid para detecção de lock fantasma.
    #
    # Retorna 0 se o lock foi adquirido.
    # Retorna 1 se outro processo válido já possui o lock.
    #
    # Casos de lock fantasma tratados automaticamente:
    #   - processo dono não existe mais (crash, kill -9, etc.)
    #   - arquivo lock/pid vazio ou corrompido
    #   - reuso de PID: outro processo assumiu o PID do dono original
    #
    # Modo de uso:
    #   lock_adquirir /tmp/meu_script.lock || { erro "Já existe uma instância rodando."; exit 1; }
    #   trap "lock_liberar /tmp/meu_script.lock" EXIT
    local lock="$1"

    # Fix 3: dry-run trata o stale separadamente para dar diagnóstico completo
    if [ "${DRYRUN:-}" = "1" ]; then
        if [ -d "$lock" ]; then
            echo "[DRY-RUN] lock_adquirir: lock fantasma detectado em '$lock' (seria removido)" >&2
        fi
        echo "[DRY-RUN] lock_adquirir: simular aquisição de '$lock'" >&2
        return 0
    fi

    # Fix 1: tenta mkdir primeiro — atômico por natureza.
    # Só verifica o conteúdo do lock existente se mkdir falhar.
    # Isso elimina a janela check → rm → mkdir onde outro processo
    # poderia criar um lock válido entre o rm e o mkdir.
    local i=0
    while [ "$i" -lt 2 ]; do
        if mkdir "$lock" 2>/dev/null; then
            echo $$ > "$lock/pid"
            return 0
        fi

        # mkdir falhou: lock existe — verificar se é válido ou fantasma
        [ -d "$lock" ] || { (( i++ )); continue; }  # sumiu entre mkdir e cá: tentar de novo

        local pid_lock
        pid_lock=$(cat "$lock/pid" 2>/dev/null)

        # Fix 2a: PID vazio ou não numérico → lock corrompido
        if [[ -z "$pid_lock" || ! "$pid_lock" =~ ^[0-9]+$ ]]; then
            rm -rf "$lock" 2>/dev/null
            (( i++ ))
            continue
        fi

        if kill -0 "$pid_lock" 2>/dev/null; then
            # Fix 2b: processo existe mas pode ser reuso de PID.
            # Se /proc/$pid foi criado DEPOIS do lock, o PID original morreu
            # e o SO o reutilizou para outro processo.
            local lock_criado proc_iniciado
            lock_criado=$(stat -c %Y "$lock/pid" 2>/dev/null || echo 0)
            proc_iniciado=$(stat -c %Y "/proc/$pid_lock" 2>/dev/null || echo 0)

            if [[ "$proc_iniciado" -gt "$lock_criado" ]]; then
                # Reuso de PID detectado: lock é fantasma
                rm -rf "$lock" 2>/dev/null
                (( i++ ))
                continue
            fi

            # Dono legítimo em execução
            return 1
        fi

        # Processo dono não existe mais: lock fantasma
        rm -rf "$lock" 2>/dev/null
        (( i++ ))
    done

    # Após duas tentativas outro processo detém o lock legitimamente
    return 1
}

function lock_liberar() {
    # Remove o lock, liberando a execução exclusiva.
    # Verifica se o processo atual é o dono do lock antes de remover,
    # evitando que um processo libere acidentalmente o lock de outro.
    # Retorna 0 se o lock foi liberado, 1 se o processo atual não é o dono.
    # Em dry-run: simula liberação sem deletar nada (lock nunca foi criado).
    #
    # Modo de uso: lock_liberar /tmp/meu_script.lock
    # Uso recomendado com trap: trap "lock_liberar /tmp/meu_script.lock" EXIT
    local lock="$1"

    if [ "${DRYRUN:-}" = "1" ]; then
        echo "[DRY-RUN] lock_liberar: simular liberação de '$lock'" >&2
        return 0
    fi

    local pid_lock
    pid_lock=$(cat "$lock/pid" 2>/dev/null)

    if [ "$pid_lock" != "$$" ]; then
        return 1
    fi

    rm -rf "$lock"
    return 0
}

function lock_adquirir_com_cleanup() {
    # Adquire o lock e registra automaticamente sua liberação no stack de cleanup
    # de sinais.sh. Garante que o lock será removido mesmo em caso de crash,
    # Ctrl+C ou qualquer outro sinal de término.
    #
    # Equivale a:
    #   lock_adquirir "$lock" && registrar_cleanup "lock_liberar $lock"
    #
    # Retorna 0 se o lock foi adquirido, 1 caso contrário.
    # Modo de uso:
    #   lock_adquirir_com_cleanup /tmp/app.lock || { erro "Já existe uma instância rodando."; exit 1; }
    local lock="$1"

    lock_adquirir "$lock" || return 1
    registrar_cleanup "lock_liberar $lock"
    return 0
}

function aguardar_processo() {
    # Espera um processo terminar, verificando a cada segundo até o timeout.
    # Aceita tanto o nome do processo quanto seu PID como identificador.
    # Retorna 0 se o processo terminou, 1 se o timeout foi atingido.
    # Modo de uso: aguardar_processo "rsync" 60
    #              aguardar_processo 1234 30
    local alvo="$1"
    local timeout="${2:-30}"
    local contador=0

    while [ "$contador" -lt "$timeout" ]; do
        if [[ "$alvo" =~ ^[0-9]+$ ]]; then
            # Identificador é um PID numérico
            kill -0 "$alvo" 2>/dev/null || return 0
        else
            # Identificador é o nome do processo
            pgrep -x "$alvo" > /dev/null 2>&1 || return 0
        fi
        sleep 1
        (( contador++ ))
    done

    return 1
}
