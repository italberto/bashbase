#!/usr/bin/env bash
# exemplo_tempu.sh - Demonstração do módulo tempu.sh
#
# Mostra os quatro padrões de uso:
#   1. tmp_criar_arquivo   — arquivo temporário com cleanup automático
#   2. tmp_criar_diretorio — diretório temporário com cleanup automático
#   3. tmp_registrar       — registro de caminho criado externamente
#   4. tmp_limpar_tudo     — liberação antecipada de temporários

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source "$BASHBASE/lib/tempu.sh"
source "$BASHBASE/lib/alerta.sh"

msg_info "=== Demonstração de tempu.sh ==="

# --- Padrão 1: arquivo temporário ---
msg_info "Criando arquivo temporário..." 1

tmp_criar_arquivo config "app-config" ".json"
msg_info "Arquivo: $config" 2

cat > "$config" <<'JSON'
{
  "ambiente": "demo",
  "versao": "1.2.0",
  "debug": true
}
JSON

msg_sucesso "Conteúdo gravado em $config" 2
msg_info "Conteúdo:" 2
cat "$config"

# --- Padrão 2: diretório temporário ---
msg_info "Criando diretório temporário..." 1

tmp_criar_diretorio staging "deploy"
msg_info "Diretório: $staging" 2

touch "$staging/artefato.war"
touch "$staging/config.env"
echo "deploy-$(date +%Y%m%d)" > "$staging/versao.txt"

msg_sucesso "Arquivos no staging:" 2
ls -1 "$staging" | while IFS= read -r f; do msg_info "$f" 3; done

# --- Padrão 3: registro de caminho externo ---
msg_info "Registrando temporário criado externamente..." 1

externo=$(mktemp --suffix=".log")
tmp_registrar "$externo"
msg_info "Registrado: $externo" 2
echo "log de demonstração" > "$externo"
msg_sucesso "Arquivo externo rastreado pelo módulo" 2

# --- Estado do rastreamento ---
msg_info "Temporários rastreados: ${#_TMP__CAMINHOS[@]}" 1
for p in "${_TMP__CAMINHOS[@]}"; do
    msg_info "$p" 2
done

# --- Padrão 4: limpeza antecipada ---
msg_info "Liberando temporários antes do fim do script..." 1
tmp_limpar_tudo

msg_info "Após tmp_limpar_tudo:" 1
for p in "$config" "$staging" "$externo"; do
    if [[ -e "$p" ]]; then
        msg_alerta "Ainda existe: $p" 2
    else
        msg_sucesso "Removido: $p" 2
    fi
done

msg_sucesso "Script concluído — nenhum temporário permanece em disco."
exit 0
