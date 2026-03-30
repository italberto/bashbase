# shellcheck shell=bash
# filesu.sh - Funções para verificação e metadados de arquivos
#
# Fornece predicados de existência, tipo e permissão, funções de conversão
# de tamanho, comparação entre arquivos e espera por eventos no sistema de arquivos.
#
# Todas as funções de predicado (e_*, arquivo_*) retornam 0 para verdadeiro e
# 1 para falso, seguindo a convenção de exit code do bash, o que permite uso
# direto em condicionais sem captura de saída.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   arquivo_existe               <arquivo>            - Verdadeiro se o arquivo existir
#   e_arquivo_vazio              <arquivo>            - Verdadeiro se existir e tiver 0 bytes
#   e_arquivo_regular            <arquivo>            - Verdadeiro se for arquivo regular (não dir, não link)
#   e_diretorio                  <arquivo>            - Verdadeiro se for diretório
#   e_link_simbolico             <arquivo>            - Verdadeiro se for link simbólico
#   e_executavel                 <arquivo>            - Verdadeiro se tiver permissão de execução
#   e_legivel                    <arquivo>            - Verdadeiro se tiver permissão de leitura
#   e_gravavel                   <arquivo>            - Verdadeiro se tiver permissão de escrita
#   e_de_propriedade_do_usuario  <arquivo> <usuario>  - Verdadeiro se o usuário for o dono
#   e_de_propriedade_do_grupo    <arquivo> <grupo>    - Verdadeiro se o grupo for o dono
#   bytes_legivel                <bytes>              - Converte bytes para formato legível (1.4 GB)
#   tamanho_do_arquivo           <arquivo>            - Tamanho em bytes (inteiro)
#   bytes_em_kilobytes           <bytes>              - Converte bytes para KB (inteiro)
#   bytes_em_megabytes           <bytes>              - Converte bytes para MB (inteiro)
#   bytes_em_gigabytes           <bytes>              - Converte bytes para GB (inteiro)
#   compara_tamanho_dos_arquivo_ab <A> <B>            - Compara tamanhos via exit code
#   diretorio_do_arquivo         <arquivo>            - Diretório pai do arquivo
#   nome_do_arquivo              <arquivo>            - Nome sem o caminho
#   extensao_do_arquivo          <arquivo>            - Extensão sem o ponto (ex: "sh", "log")
#   get_data_hora_ultima_modificacao <arquivo>        - Data e hora da última modificação
#   aguardar_arquivo             <arquivo> <modo> [timeout] - Aguarda arquivo aparecer ou sumir


[[ -n "${_FILESU_SH_LOADED:-}" ]] && return 0
readonly _FILESU_SH_LOADED=1

function arquivo_existe() {
    # Retorna 0 se o caminho informado existir e for um arquivo regular.
    # Retorna 1 para diretórios, links simbólicos quebrados e caminhos inexistentes.
    # Modo de uso: arquivo_existe /etc/hosts && echo "hosts encontrado"
    #              arquivo_existe "$config" || { erro "Configuração não encontrada"; exit 1; }
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_arquivo_vazio() {
    # Retorna 0 se o arquivo existir e seu tamanho for zero bytes.
    # Retorna 1 se o arquivo não existir ou tiver conteúdo.
    # Útil para verificar se um comando gerou saída antes de processar o resultado.
    # Modo de uso: e_arquivo_vazio /tmp/saida.txt && erro "Nenhum resultado gerado"
    #              e_arquivo_vazio "$log" || info "Log contém $(conta_linhas "$log") linhas"
    local arquivo="$1"
    if [[ -s "$arquivo" ]]; then
        return 1
    else
        return 0
    fi
}

function e_arquivo_regular() {
    # Retorna 0 se o caminho existir e for um arquivo regular (não diretório,
    # não dispositivo de bloco, não pipe, não socket).
    # Links simbólicos que apontam para um arquivo regular retornam 0.
    # Funcionalmente equivalente a arquivo_existe; use quando o contexto
    # semântico for "tipo de entrada" em vez de "existência".
    # Modo de uso: e_arquivo_regular "$entrada" || { erro "Esperado arquivo regular"; exit 1; }
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_diretorio() {
    # Retorna 0 se o caminho existir e for um diretório.
    # Links simbólicos que apontam para um diretório retornam 0.
    # Retorna 1 para arquivos regulares, pipes, sockets e caminhos inexistentes.
    # Modo de uso: e_diretorio /var/backups || mkdir -p /var/backups
    #              e_diretorio "$destino" || { erro "Destino não é diretório"; exit 1; }
    local arquivo="$1"
    if [[ -d "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_link_simbolico() {
    # Retorna 0 se o caminho existir e for um link simbólico.
    # Links quebrados (apontando para alvo inexistente) também retornam 0.
    # Retorna 1 para arquivos regulares, diretórios e caminhos inexistentes.
    # Modo de uso: e_link_simbolico /usr/bin/python && echo "python é um link"
    local arquivo="$1"
    if [[ -L "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_executavel() {
    # Retorna 0 se o arquivo existir e o processo atual tiver permissão de execução.
    # A permissão é verificada para o usuário efetivo (EUID) do processo.
    # Retorna 1 se o arquivo não existir ou não for executável pelo usuário atual.
    # Modo de uso: e_executavel /usr/bin/curl || { erro "curl não encontrado ou sem permissão"; exit 1; }
    #              e_executavel "$script" || chmod +x "$script"
    local arquivo="$1"
    if [[ -x "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_legivel() {
    # Retorna 0 se o arquivo existir e o processo atual tiver permissão de leitura.
    # Retorna 1 se o arquivo não existir ou a leitura for negada pelo sistema.
    # Útil antes de tentar ler arquivos que podem ter permissões restritas.
    # Modo de uso: e_legivel /etc/shadow || { erro "Sem permissão para ler /etc/shadow"; exit 1; }
    local arquivo="$1"
    if [[ -r "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_gravavel() {
    # Retorna 0 se o arquivo existir e o processo atual tiver permissão de escrita.
    # Retorna 1 se o arquivo não existir ou a escrita for negada pelo sistema.
    # Verificar antes de modificar evita erros parciais em scripts de automação.
    # Modo de uso: e_gravavel "$config" || { erro "Arquivo de configuração somente leitura"; exit 1; }
    local arquivo="$1"
    if [[ -w "$arquivo" ]]; then
        return 0
    else
        return 1
    fi
}

function e_de_propriedade_do_usuario() {
    # Retorna 0 se o arquivo pertencer ao usuário informado.
    # Compara pelo nome de usuário, não pelo UID.
    # Retorna 1 se o arquivo não existir ou pertencer a outro usuário.
    # Modo de uso: e_de_propriedade_do_usuario /var/www/html "www-data" || alerta "Dono incorreto"
    #              e_de_propriedade_do_usuario "$arq" "$(whoami)" || erro "Arquivo não é seu"
    local arquivo="$1"
    local usuario="$2"
    if [[ $(stat -c "%U" "$arquivo") == "$usuario" ]]; then
        return 0
    else
        return 1
    fi
}

function e_de_propriedade_do_grupo() {
    # Retorna 0 se o arquivo pertencer ao grupo informado.
    # Compara pelo nome do grupo, não pelo GID.
    # Retorna 1 se o arquivo não existir ou pertencer a outro grupo.
    # Modo de uso: e_de_propriedade_do_grupo /var/log/app "syslog" || alerta "Grupo incorreto"
    local arquivo="$1"
    local grupo="$2"
    if [[ $(stat -c "%G" "$arquivo") == "$grupo" ]]; then
        return 0
    else
        return 1
    fi
}

function bytes_legivel() {
    # Converte um valor em bytes para formato legível por humanos com unidade automática.
    # Usa uma casa decimal para KB, MB, GB e TB; inteiro puro para valores menores que 1 KB.
    # Retorna a string formatada no stdout (ex: "512 B", "1.4 KB", "234.7 MB", "2.1 GB").
    # Modo de uso: bytes_legivel 1503238553          → "1.4 GB"
    #              bytes_legivel 512                 → "512 B"
    #              echo "Tamanho: $(bytes_legivel "$(tamanho_do_arquivo /var/log/syslog)")"
    local bytes="$1"
    awk -v b="$bytes" 'BEGIN {
        split("B KB MB GB TB", u)
        n = 1
        while (b >= 1024 && n < 5) { b /= 1024; n++ }
        if (n == 1) printf "%d %s\n", b, u[n]
        else        printf "%.1f %s\n", b, u[n]
    }'
}

function tamanho_do_arquivo() {
    # Retorna o tamanho do arquivo em bytes como inteiro puro, sem unidade.
    # Use bytes_legivel para converter para formato humano, ou bytes_em_kilobytes/
    # bytes_em_megabytes/bytes_em_gigabytes para conversões inteiras.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tamanho_do_arquivo /var/log/syslog         → 45231
    #              tam=$(tamanho_do_arquivo "$arq")
    #              [ "$tam" -gt 1048576 ] && alerta "Arquivo maior que 1 MB"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        stat -c "%s" "$arquivo"
    else
        return 1
    fi
}

function bytes_em_kilobytes() {
    # Converte bytes para kilobytes usando divisão inteira (sem arredondamento).
    # Para formato com unidade legível, prefira bytes_legivel.
    # Modo de uso: bytes_em_kilobytes 2048    → 2
    #              bytes_em_kilobytes 1500    → 1   (truncamento inteiro)
    local bytes="$1"
    echo $((bytes / 1024))
}

function bytes_em_megabytes() {
    # Converte bytes para megabytes usando divisão inteira (sem arredondamento).
    # Para formato com unidade legível, prefira bytes_legivel.
    # Modo de uso: bytes_em_megabytes 5242880    → 5
    local bytes="$1"
    echo $((bytes / 1024 / 1024))
}

function bytes_em_gigabytes() {
    # Converte bytes para gigabytes usando divisão inteira (sem arredondamento).
    # Para formato com unidade legível, prefira bytes_legivel.
    # Modo de uso: bytes_em_gigabytes 10737418240    → 10
    local bytes="$1"
    echo $((bytes / 1024 / 1024 / 1024))
}

function compara_tamanho_dos_arquivo_ab() {
    # Compara o tamanho em bytes de dois arquivos e sinaliza o resultado via exit code:
    #   0  — os dois arquivos têm o mesmo tamanho
    #   1  — o arquivo A é maior que o arquivo B
    #   2  — o arquivo A é menor que o arquivo B
    #   3  — um ou ambos os arquivos não existem
    #
    # O resultado é comunicado APENAS pelo exit code — nenhuma saída é impressa.
    # Use em case/if para distinguir os três casos possíveis.
    #
    # Modo de uso:
    #   compara_tamanho_dos_arquivo_ab original.tar backup.tar
    #   case $? in
    #       0) echo "Tamanhos idênticos"         ;;
    #       1) echo "Original é maior que backup" ;;
    #       2) echo "Backup é maior que original" ;;
    #       3) erro "Um dos arquivos não existe"  ;;
    #   esac
    local arquivoA="$1"
    local arquivoB="$2"
    if [[ ! -f "$arquivoA" || ! -f "$arquivoB" ]]; then
        return 3
    fi
    local sizeA sizeB
    sizeA=$(stat -c "%s" "$arquivoA")
    sizeB=$(stat -c "%s" "$arquivoB")
    if [[ $sizeA -gt $sizeB ]]; then
        return 1
    elif [[ $sizeA -lt $sizeB ]]; then
        return 2
    else
        return 0
    fi
}

function diretorio_do_arquivo() {
    # Retorna o caminho do diretório que contém o arquivo (equivalente ao dirname).
    # O arquivo deve existir; retorna 1 caso contrário.
    # Modo de uso: diretorio_do_arquivo /etc/nginx/nginx.conf   → "/etc/nginx"
    #              cd "$(diretorio_do_arquivo "$0")"             (muda para o dir do script)
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        dirname "$arquivo"
    else
        return 1
    fi
}

function nome_do_arquivo() {
    # Retorna apenas o nome do arquivo, sem o caminho (equivalente ao basename).
    # O arquivo deve existir; retorna 1 caso contrário.
    # Modo de uso: nome_do_arquivo /etc/nginx/nginx.conf   → "nginx.conf"
    #              nome=$(nome_do_arquivo "$caminho_completo")
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        basename "$arquivo"
    else
        return 1
    fi
}

function extensao_do_arquivo() {
    # Retorna a extensão do arquivo sem o ponto separador.
    # Se o arquivo não tiver extensão, retorna o nome completo.
    # O arquivo deve existir; retorna 1 caso contrário.
    # Modo de uso: extensao_do_arquivo /var/log/app.log     → "log"
    #              extensao_do_arquivo /usr/bin/bash         → "bash"  (sem extensão)
    #              ext=$(extensao_do_arquivo "$arq")
    #              [ "$ext" = "sh" ] || erro "Esperado arquivo .sh"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        echo "${arquivo##*.}"
    else
        return 1
    fi
}

function get_data_hora_ultima_modificacao() {
    # Retorna a data e hora da última modificação do arquivo no formato
    # "YYYY-MM-DD HH:MM:SS.NNNNNNNNN +ZZZZ" (saída bruta do stat).
    # Para arquivos, a modificação ocorre quando o conteúdo é alterado.
    # Funciona também com diretórios (modificação ocorre quando o conteúdo muda).
    # Retorna 1 se o caminho não existir.
    # Modo de uso: get_data_hora_ultima_modificacao /etc/hosts
    #              echo "Modificado em: $(get_data_hora_ultima_modificacao "$arq")"
    local arquivo="$1"
    if [[ -e "$arquivo" ]]; then
        stat -c "%y" "$arquivo" 2>/dev/null
    else
        return 1
    fi
}

function aguardar_arquivo() {
    # Aguarda um arquivo aparecer ou desaparecer no sistema de arquivos,
    # verificando a cada segundo até o timeout ser atingido.
    # Útil em pipelines de automação onde um processo sinaliza conclusão
    # criando ou removendo um arquivo (ex: lockfiles, arquivos de status).
    #
    # Modos disponíveis:
    #   "aparecer"    — retorna 0 quando o arquivo for criado
    #   "desaparecer" — retorna 0 quando o arquivo for removido
    #
    # Retorna 0 se a condição for satisfeita antes do timeout.
    # Retorna 1 se o timeout for atingido sem que a condição se cumpra.
    #
    # Modo de uso:
    #   # Aguardar até 60s que um processo crie um arquivo de conclusão:
    #   aguardar_arquivo /tmp/processo.done aparecer 60 || erro "Timeout: processo não concluiu"
    #
    #   # Aguardar até 30s que um lockfile seja liberado:
    #   aguardar_arquivo /var/run/app.lock desaparecer 30 || erro "Timeout: lock não liberado"
    #
    #   $1 = caminho do arquivo a monitorar
    #   $2 = "aparecer" ou "desaparecer"
    #   $3 = timeout em segundos (padrão: 30)
    local arquivo="$1"
    local modo="${2:-aparecer}"
    local timeout="${3:-30}"
    local contador=0

    while [ "$contador" -lt "$timeout" ]; do
        if [ "$modo" = "aparecer" ] && [ -f "$arquivo" ]; then
            return 0
        elif [ "$modo" = "desaparecer" ] && [ ! -f "$arquivo" ]; then
            return 0
        fi
        sleep 1
        (( contador++ ))
    done

    return 1
}
