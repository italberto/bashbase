# shellcheck shell=bash
# argsu.sh - Parsing declarativo de argumentos de linha de comando
#
# Permite declarar os argumentos aceitos por um script e parsear "$@" de forma
# automática, com suporte a --flag valor, --flag=valor, flags booleanas,
# argumentos posicionais e geração automática de --help.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   arg_definir  <--flag> <VAR> [padrao] [descricao] [tipo] - Declara um argumento aceito
#   arg_parsear  "$@"                                       - Parseia os argumentos do script
#   arg_ajuda                                               - Imprime a mensagem de ajuda
#   arg_resetar                                             - Limpa todas as definições
#
# Variável global preenchida por arg_parsear:
#   _ARG__POSICIONAIS   Array com os argumentos posicionais capturados
#
# Modo de uso típico:
#   source $BASHBASE/argsu.sh
#
#   arg_definir "--host"    HOST    "localhost" "Endereço do servidor"
#   arg_definir "--porta"   PORTA   8080        "Porta de conexão"
#   arg_definir "--verbose" VERBOSE ""          "Ativar saída detalhada" "boolean"
#   arg_definir "--saida"   SAIDA   ""          "Arquivo de saída"       "valor"
#   arg_parsear "$@" || exit 1
#
#   echo "Conectando em $HOST:$PORTA"
#   [ "$VERBOSE" = "1" ] && echo "Modo verboso ativado"
#   echo "Arquivos: ${_ARG__POSICIONAIS[*]}"
#
# Tipos de argumento (5º parâmetro de arg_definir):
#   "boolean"   Flag sem valor: recebe "1" quando presente, "" quando ausente.
#               Inferido automaticamente quando o valor padrão for vazio.
#   "valor"     Flag que exige um valor explícito na linha de comando; erro se ausente.
#               Inferido automaticamente quando o valor padrão for não vazio.
#               Passar explicitamente quando a flag não tem padrão mas exige valor.
#
# Argumentos posicionais (não iniciados com -):
#   Capturados automaticamente no array global _ARG__POSICIONAIS.
#   O marcador "--" força que todos os argumentos seguintes sejam posicionais,
#   mesmo que comecem com "-".
#
# Sintaxe de valor suportada:
#   --flag valor      (separado por espaço)
#   --flag=valor      (separado por sinal de igual)


[[ -n "${_ARGSU_SH_LOADED:-}" ]] && return 0
readonly _ARGSU_SH_LOADED=1

# Registros paralelos de definições de argumentos
_ARG__FLAGS=()
_ARG__VARS=()
_ARG__PADROES=()
_ARG__DESCS=()
_ARG__TIPOS=()

# Argumentos posicionais capturados por arg_parsear
_ARG__POSICIONAIS=()

function arg_definir() {
    # Declara um argumento aceito pelo script com sua variável de destino,
    # valor padrão, descrição e tipo.
    #
    # Parâmetros:
    #   $1 - flag da linha de comando (ex: --host)
    #   $2 - nome da variável de destino (ex: HOST)
    #   $3 - valor padrão; "" ou omitido indica ausência de padrão
    #   $4 - descrição exibida no --help
    #   $5 - tipo: "boolean" ou "valor" (opcional; inferido se omitido)
    #
    # Inferência automática do tipo quando $5 for omitido:
    #   padrão vazio     → boolean: recebe "1" quando presente, "" quando ausente
    #   padrão não vazio → valor:   exige um valor explícito; erro se ausente
    # Passar $5 explicitamente quando a inferência não for suficiente
    # (ex: flag do tipo "valor" sem padrão definido).
    #
    # Modo de uso:
    #   arg_definir "--host"    HOST    "localhost" "Endereço do servidor"
    #   arg_definir "--verbose" VERBOSE ""          "Modo verboso"     "boolean"
    #   arg_definir "--saida"   SAIDA   ""          "Arquivo de saída" "valor"
    local flag="$1" var="$2" padrao="${3:-}" desc="${4:-}" tipo="${5:-}"

    if [[ -z "$tipo" ]]; then
        [[ -z "$padrao" ]] && tipo="boolean" || tipo="valor"
    fi

    _ARG__FLAGS+=("$flag")
    _ARG__VARS+=("$var")
    _ARG__PADROES+=("$padrao")
    _ARG__DESCS+=("$desc")
    _ARG__TIPOS+=("$tipo")

    [ -n "$padrao" ] && printf -v "$var" '%s' "$padrao"
}

function arg_parsear() {
    # Parseia os argumentos do script ($@) e preenche as variáveis declaradas
    # com arg_definir. Retorna 1 em caso de:
    #   - argumento desconhecido
    #   - flag do tipo "valor" fornecida sem valor
    #   - --help ou -h passado (exibe ajuda antes de retornar)
    # Argumentos posicionais (não iniciados com "-") são acumulados em _ARG__POSICIONAIS.
    # O marcador "--" força todos os tokens seguintes como posicionais,
    # mesmo que comecem com "-".
    # Modo de uso: arg_parsear "$@" || exit 1
    _ARG__POSICIONAIS=()
    local separador=0

    while [[ $# -gt 0 ]]; do
        local chave="$1"

        # Após "--", tudo vai para posicionais independente do formato
        if [[ "$separador" -eq 1 ]]; then
            _ARG__POSICIONAIS+=("$chave")
            shift
            continue
        fi

        if [[ "$chave" == "--" ]]; then
            separador=1
            shift
            continue
        fi

        if [[ "$chave" == "--help" || "$chave" == "-h" ]]; then
            arg_ajuda
            return 1
        fi

        # Argumento posicional (não começa com -)
        if [[ "$chave" != -* ]]; then
            _ARG__POSICIONAIS+=("$chave")
            shift
            continue
        fi

        local encontrado=0 i
        for i in "${!_ARG__FLAGS[@]}"; do
            local flag="${_ARG__FLAGS[$i]}" var="${_ARG__VARS[$i]}" tipo="${_ARG__TIPOS[$i]}"

            if [[ "$chave" == "$flag" ]]; then
                encontrado=1
                if [[ "$tipo" == "boolean" ]]; then
                    printf -v "$var" '%s' "1"
                elif [[ $# -ge 2 && "${2:-}" != -* ]]; then
                    printf -v "$var" '%s' "$2"
                    shift
                elif [[ $# -lt 2 ]]; then
                    echo "Flag '$flag' requer um valor mas nenhum argumento foi fornecido após ela" >&2
                    arg_ajuda >&2
                    return 1
                else
                    echo "Flag '$flag' requer um valor mas o próximo argumento é uma flag ('$2')" >&2
                    arg_ajuda >&2
                    return 1
                fi
                break
            elif [[ "$chave" == "$flag="* ]]; then
                encontrado=1
                printf -v "$var" '%s' "${chave#*=}"
                break
            fi
        done

        if [[ "$encontrado" -eq 0 ]]; then
            echo "Argumento desconhecido: $chave" >&2
            arg_ajuda >&2
            return 1
        fi

        shift
    done
}

function arg_ajuda() {
    # Exibe a lista de argumentos declarados com suas descrições e valores padrão.
    # Chamada automaticamente por arg_parsear ao receber --help/-h ou argumento inválido.
    # Modo de uso: arg_ajuda
    echo "Opções disponíveis:"
    local i
    for i in "${!_ARG__FLAGS[@]}"; do
        local flag="${_ARG__FLAGS[$i]}"
        local desc="${_ARG__DESCS[$i]}"
        local padrao="${_ARG__PADROES[$i]}"
        local tipo="${_ARG__TIPOS[$i]}"
        if [[ "$tipo" == "boolean" ]]; then
            printf "  %-22s %s\n" "$flag" "$desc"
        elif [ -n "$padrao" ]; then
            printf "  %-22s %s (padrão: %s)\n" "$flag" "$desc" "$padrao"
        else
            printf "  %-22s %s\n" "$flag" "$desc"
        fi
    done
    printf "  %-22s %s\n" "--help, -h" "Exibe esta mensagem de ajuda"
}

function arg_resetar() {
    # Remove todas as definições de argumento registradas e limpa _ARG__POSICIONAIS.
    # Útil quando argsu.sh é reutilizado em múltiplos contextos num mesmo processo.
    # Modo de uso: arg_resetar
    _ARG__FLAGS=()
    _ARG__VARS=()
    _ARG__PADROES=()
    _ARG__DESCS=()
    _ARG__TIPOS=()
    _ARG__POSICIONAIS=()
}
