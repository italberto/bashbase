# shellcheck shell=bash
# tempu.sh - Criação e cleanup automático de arquivos e diretórios temporários
#
# Fornece funções para criar arquivos e diretórios temporários que são
# removidos automaticamente ao fim do script — seja por saída normal, SIGINT,
# SIGTERM ou SIGHUP — por meio da integração com a pilha de cleanup de sinais.sh.
#
# As funções tmp_criar_arquivo e tmp_criar_diretorio recebem o nome de uma
# variável como primeiro argumento e a preenchem com o caminho criado
# (padrão nameref do Bash). Isso evita subshells e garante que o cleanup
# seja registrado no processo correto.
#
# Para arquivos criados fora deste módulo (ex: por mktemp diretamente),
# use tmp_registrar para inclui-los no cleanup automático.
#
# Para liberar temporários antes do fim do script, use tmp_limpar_tudo.
# Os handlers registrados em sinais.sh tentarão remover os caminhos
# novamente no EXIT, mas rm sobre caminho inexistente é inofensivo.
#
# Requer Bash 4.3+ (nameref via local -n).
#
# Dependências: sinais.sh, alerta.sh
#
# Funções disponíveis:
#   tmp_criar_arquivo    <variavel> [prefixo] [sufixo] - Cria arquivo temporário com cleanup automático
#   tmp_criar_diretorio  <variavel> [prefixo]          - Cria diretório temporário com cleanup automático
#   tmp_registrar        <caminho>                     - Registra caminho existente para cleanup automático
#   tmp_limpar_tudo                                    - Remove imediatamente todos os temporários do módulo


[[ -n "${_TEMPU_SH_LOADED:-}" ]] && return 0
readonly _TEMPU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/sinais.sh"
source "$(dirname "${BASH_SOURCE[0]}")/alerta.sh"

# Array interno com todos os caminhos registrados por este módulo
_TMP__CAMINHOS=()

function tmp_criar_arquivo() {
    # Cria um arquivo temporário e o registra para remoção automática na saída do script.
    # O caminho criado é armazenado na variável cujo nome foi passado como primeiro argumento.
    # O arquivo é criado em $TMPDIR (ou /tmp se não definido).
    # O nome segue o padrão: <prefixo>.XXXXXX<sufixo>
    # Retorna 1 se mktemp falhar.
    # Modo de uso: tmp_criar_arquivo meu_arq
    #              tmp_criar_arquivo cfg "app-config" ".json"
    #              echo "conteúdo" > "$meu_arq"
    local -n _tmp_var_ref="$1"
    local prefixo="${2:-tmp}"
    local sufixo="${3:-}"

    local caminho
    if [[ -n "$sufixo" ]]; then
        caminho=$(mktemp --suffix="$sufixo" "${TMPDIR:-/tmp}/${prefixo}.XXXXXX") || {
            erro "Falha ao criar arquivo temporário."
            return 1
        }
    else
        caminho=$(mktemp "${TMPDIR:-/tmp}/${prefixo}.XXXXXX") || {
            erro "Falha ao criar arquivo temporário."
            return 1
        }
    fi

    _tmp_var_ref="$caminho"
    _TMP__CAMINHOS+=("$caminho")
    registrar_cleanup_cmd rm -f "$caminho"
}

function tmp_criar_diretorio() {
    # Cria um diretório temporário e o registra para remoção automática na saída do script.
    # O caminho criado é armazenado na variável cujo nome foi passado como primeiro argumento.
    # O diretório é criado em $TMPDIR (ou /tmp se não definido).
    # O nome segue o padrão: <prefixo>.XXXXXX
    # O diretório e todo o seu conteúdo são removidos (rm -rf) no cleanup.
    # Retorna 1 se mktemp falhar.
    # Modo de uso: tmp_criar_diretorio staging_dir
    #              tmp_criar_diretorio work_dir "deploy"
    #              cp artefatos/* "$staging_dir/"
    local -n _tmp_var_ref="$1"
    local prefixo="${2:-tmp}"

    local caminho
    caminho=$(mktemp -d "${TMPDIR:-/tmp}/${prefixo}.XXXXXX") || {
        erro "Falha ao criar diretório temporário."
        return 1
    }

    _tmp_var_ref="$caminho"
    _TMP__CAMINHOS+=("$caminho")
    registrar_cleanup_cmd rm -rf "$caminho"
}

function tmp_registrar() {
    # Registra um caminho existente (arquivo ou diretório) para remoção automática
    # na saída do script, como se tivesse sido criado por este módulo.
    # Útil para arquivos criados via mktemp diretamente ou em subshells.
    # O caminho é removido com rm -rf (cobre tanto arquivos quanto diretórios).
    # Retorna 1 se o caminho não existir.
    # Modo de uso: arq=$(mktemp)
    #              tmp_registrar "$arq"
    local caminho="$1"

    if [[ ! -e "$caminho" ]]; then
        erro "Caminho não encontrado para registrar no cleanup: $caminho"
        return 1
    fi

    _TMP__CAMINHOS+=("$caminho")
    registrar_cleanup_cmd rm -rf "$caminho"
}

function tmp_limpar_tudo() {
    # Remove imediatamente todos os arquivos e diretórios registrados por este módulo.
    # Útil quando os temporários não são mais necessários antes do fim do script
    # e o espaço em disco é uma preocupação.
    # Os handlers registrados em sinais.sh tentarão remover os caminhos novamente
    # no EXIT, mas rm sobre caminho inexistente é inofensivo.
    # Modo de uso: tmp_limpar_tudo
    local caminho
    for caminho in "${_TMP__CAMINHOS[@]}"; do
        rm -rf "$caminho" 2>/dev/null
    done
    _TMP__CAMINHOS=()
}
