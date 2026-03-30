# shellcheck shell=bash
# version.sh - Metadados e informações de versão da biblioteca bashbase
#
# Expõe a versão atual, dados de autoria e licença como variáveis readonly,
# além de uma função para exibição formatada dessas informações.
# A versão é lida do arquivo VERSION na raiz do repositório, mantendo
# uma única fonte canônica.
#
# Dependências: nenhuma
#
# Variáveis exportadas:
#   BASHBASE_VERSION       - Versão atual (ex: 1.0.0)
#   BASHBASE_RELEASE_DATE  - Data da release atual (AAAA-MM-DD)
#   BASHBASE_AUTHOR        - Nome do autor
#   BASHBASE_AUTHOR_EMAIL  - E-mail do autor
#   BASHBASE_LICENSE       - Licença do projeto
#
# Funções disponíveis:
#   bashbase_versao        - Exibe versão, autoria e licença no stdout

[[ -n "${_VERSION_SH_LOADED:-}" ]] && return 0
readonly _VERSION_SH_LOADED=1

BASHBASE_VERSION=$(< "$(dirname "${BASH_SOURCE[0]}")/../VERSION")
BASHBASE_VERSION="${BASHBASE_VERSION//$'\n'/}"
readonly BASHBASE_VERSION

readonly BASHBASE_RELEASE_DATE="2026-03-29"
readonly BASHBASE_AUTHOR="kaliope"
readonly BASHBASE_AUTHOR_EMAIL=""
readonly BASHBASE_LICENSE="MIT"

# bashbase_versao
#   Exibe versão, data de release, autoria e licença no stdout.
bashbase_versao() {
    echo "bashbase v${BASHBASE_VERSION} (${BASHBASE_RELEASE_DATE})"
    echo "Autor:   ${BASHBASE_AUTHOR}${BASHBASE_AUTHOR_EMAIL:+ <${BASHBASE_AUTHOR_EMAIL}>}"
    echo "Licença: ${BASHBASE_LICENSE}"
}
