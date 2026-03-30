#!/usr/bin/env bash
# install.sh - Configura a variável BASHBASE no perfil do shell do usuário
#
# Define BASHBASE apontando para o diretório raiz do repositório e
# adiciona a exportação ao ~/.bashrc ou ~/.zshrc, conforme o shell ativo.
# Idempotente: não duplica a linha se já estiver presente.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPORT_LINE="export BASHBASE=\"${REPO_DIR}\""

# Detecta o arquivo de perfil do shell atual
if [[ "${SHELL:-}" == */zsh ]]; then
    PROFILE="$HOME/.zshrc"
elif [[ "${SHELL:-}" == */bash ]]; then
    PROFILE="$HOME/.bashrc"
else
    echo "Shell não reconhecido: ${SHELL:-desconhecido}"
    echo "Adicione manualmente ao seu perfil:"
    echo "  ${EXPORT_LINE}"
    exit 1
fi

# Adiciona apenas se ainda não estiver presente
if grep -qF "BASHBASE=" "$PROFILE" 2>/dev/null; then
    echo "BASHBASE já está configurado em ${PROFILE}."
else
    printf '\n# bashbase\n%s\n' "$EXPORT_LINE" >> "$PROFILE"
    echo "BASHBASE configurado em ${PROFILE}."
fi

echo "  BASHBASE=${REPO_DIR}"
echo
echo "Para aplicar na sessão atual:"
echo "  source ${PROFILE}"
