# shellcheck shell=bash
# boolean.sh - Funções utilitárias para interpretação de valores booleanos
#
# Centraliza a lógica de verificação de verdadeiro/falso, aceitando múltiplos
# formatos de entrada. Útil para interpretar variáveis de ambiente vindas de
# arquivos de configuração ou outras fontes externas que possam usar formatos
# diferentes do padrão adotado internamente ("1"/"").
#
# Padrão adotado nesta biblioteca:
#   "1"  → verdadeiro   (argsu.sh, inputs.sh, alerta.sh)
#   ""   → falso
#   0-3  → numérico     (logu.sh — exclusivo para níveis de log)
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   eh_verdadeiro  <valor>  - Retorna 0 se o valor for considerado verdadeiro
#   eh_falso       <valor>  - Retorna 0 se o valor for considerado falso


[[ -n "${_BOOLEAN_SH_LOADED:-}" ]] && return 0
readonly _BOOLEAN_SH_LOADED=1

function eh_verdadeiro() {
    # Retorna 0 se o valor for reconhecido como afirmativo, 1 se negativo,
    # ou 2 se o valor não for reconhecido.
    # Aceita: 1, true, yes, sim, on  (e variantes entre aspas)
    # Rejeita: 0, false, no, não, off, "" (vazio)
    # Modo de uso: eh_verdadeiro "$DEBUG" && echo "Debug ativado"
    local valor="${1:-}"
    case "$valor" in
        1|"1"|true|"true"|yes|"yes"|sim|"sim"|on|"on") return 0 ;;
        0|"0"|false|"false"|no|"no"|não|"não"|off|"off"|"") return 1 ;;
        *) return 2 ;;
    esac
}

function eh_falso() {
    # Retorna 0 se o valor for reconhecido como negativo, 1 se afirmativo,
    # ou 2 se o valor não for reconhecido.
    # Inverso exato de eh_verdadeiro.
    # Modo de uso: eh_falso "$VERBOSE" && echo "Modo silencioso"
    local valor="${1:-}"
    case "$valor" in
        0|"0"|false|"false"|no|"no"|não|"não"|off|"off"|"") return 0 ;;
        1|"1"|true|"true"|yes|"yes"|sim|"sim"|on|"on") return 1 ;;
        *) return 2 ;;
    esac
}
