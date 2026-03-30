# shellcheck shell=bash
# cores.sh - Funções para estilização de texto no terminal usando códigos de escape ANSI
#
# Permite exibir texto colorido no terminal de forma simples.
# Os códigos ANSI funcionam na maioria dos terminais modernos compatíveis com VT100.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   cor_vermelho <texto> - Exibe texto em vermelho
#   cor_verde    <texto> - Exibe texto em verde
#   cor_amarelo  <texto> - Exibe texto em amarelo
#   cor_azul     <texto> - Exibe texto em azul
#
# Todas as funções terminam com \n, funcionando tanto standalone quanto inline.
# Uso standalone: cor_verde "operação concluída"
# Uso inline:     printf "Resultado: %s e %s\n" "$(cor_verde OK)" "$(cor_vermelho FALHOU)"
#                 (a substituição de comando absorve o \n interno)

[[ -n "${_CORES_SH_LOADED:-}" ]] && return 0
readonly _CORES_SH_LOADED=1

function cor_vermelho() {
    # Exibe o texto em vermelho seguido de quebra de linha.
    # Modo de uso: cor_vermelho "mensagem de erro"
    #              printf "Status: %s\n" "$(cor_vermelho FALHOU)"
    printf '\033[31m%s\033[0m\n' "$1"
}

function cor_verde() {
    # Exibe o texto em verde seguido de quebra de linha.
    # Modo de uso: cor_verde "operação concluída"
    #              printf "Status: %s\n" "$(cor_verde OK)"
    printf '\033[32m%s\033[0m\n' "$1"
}

function cor_amarelo() {
    # Exibe o texto em amarelo seguido de quebra de linha.
    # Modo de uso: cor_amarelo "atenção: verifique as configurações"
    #              printf "[%s] mensagem\n" "$(cor_amarelo AVISO)"
    printf '\033[33m%s\033[0m\n' "$1"
}

function cor_azul() {
    # Exibe o texto em azul seguido de quebra de linha.
    # Modo de uso: cor_azul "informação adicional"
    #              printf "[%s] Sistema iniciado\n" "$(cor_azul INFO)"
    printf '\033[34m%s\033[0m\n' "$1"
}
