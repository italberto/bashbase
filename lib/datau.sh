# shellcheck shell=bash
# datau.sh - Funções utilitárias para manipulação de data e tempo
#
# Fornece funções para formatação de datas, cálculo de durações e
# geração de timestamps para uso em nomes de arquivos e logs.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   timestamp          - Retorna data/hora compacta para nomes de arquivo
#   data_formatada     - Retorna data/hora legível (DD/MM/YYYY HH:MM:SS)
#   data_iso           - Retorna data no formato ISO 8601
#   data_unix          - Retorna o timestamp Unix atual (segundos desde epoch)
#   duracao            - Calcula segundos entre dois timestamps Unix
#   duracao_formatada  - Converte segundos para o formato HH:MM:SS

[[ -n "${_DATAU_SH_LOADED:-}" ]] && return 0
readonly _DATAU_SH_LOADED=1

function timestamp() {
    # Retorna a data e hora atual em formato compacto, sem espaços ou separadores,
    # adequado para uso em nomes de arquivos e diretórios.
    # Formato: YYYYMMDD_HHMMSS
    # Modo de uso: arquivo="backup_$(timestamp).tar.gz"
    date '+%Y%m%d_%H%M%S'
}

function data_formatada() {
    # Retorna a data e hora atual em formato legível para exibição ao usuário.
    # Formato: DD/MM/YYYY HH:MM:SS
    # Modo de uso: echo "Iniciado em: $(data_formatada)"
    date '+%d/%m/%Y %H:%M:%S'
}

function data_iso() {
    # Retorna a data e hora atual no formato ISO 8601, amplamente usado em
    # integrações com APIs e sistemas externos.
    # Formato: YYYY-MM-DDTHH:MM:SS
    # Modo de uso: echo "Timestamp ISO: $(data_iso)"
    date '+%Y-%m-%dT%H:%M:%S'
}

function data_unix() {
    # Retorna o timestamp Unix atual: número de segundos desde 01/01/1970 00:00:00 UTC.
    # Útil como ponto de referência para calcular durações com duracao().
    # Modo de uso: inicio=$(data_unix)
    #              # ... operações ...
    #              fim=$(data_unix)
    #              echo "Duração: $(duracao $inicio $fim) segundos"
    date '+%s'
}

function duracao() {
    # Calcula a duração em segundos entre dois timestamps Unix.
    # Os valores de início e fim devem ser obtidos com data_unix() ou date '+%s'.
    # Modo de uso: duracao <inicio> <fim>
    #              duracao 1700000000 1700003600   # retorna 3600
    local inicio="$1"
    local fim="$2"
    echo $(( fim - inicio ))
}

function duracao_formatada() {
    # Converte uma duração em segundos para o formato legível HH:MM:SS.
    # Combina bem com duracao() para exibir o tempo decorrido de uma operação.
    # Modo de uso: duracao_formatada 3661   # retorna 01:01:01
    #              duracao_formatada $(duracao $inicio $(data_unix))
    local segundos_total="$1"
    local horas=$(( segundos_total / 3600 ))
    local minutos=$(( (segundos_total % 3600) / 60 ))
    local segundos=$(( segundos_total % 60 ))
    printf '%02d:%02d:%02d' "$horas" "$minutos" "$segundos"
}
