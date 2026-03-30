#!/bin/bash

# exemplo_retryu.sh - Exemplos de uso das funções de retry do retryu.sh
#
# Demonstra as quatro funções disponíveis:
#   tentar              - Retry simples com delay fixo (sem spinner)
#   tentar_com_backoff  - Retry com espera exponencial (sem spinner)
#   tentar_spinner      - Retry com delay fixo e spinner visual
#   tentar_backoff_spinner - Retry com espera exponencial e spinner visual
#
# Pré-requisito: variável BASHBASE deve apontar para o diretório da biblioteca.
#   export BASHBASE="/caminho/para/bashbase"

set -euo pipefail

if [ -z "$BASHBASE" ]; then
    echo "Variável BASHBASE não definida."
    exit 1
fi

source $BASHBASE/lib/retryu.sh
source $BASHBASE/lib/alerta.sh

# ---------------------------------------------------------------------------
# Funções auxiliares usadas nos exemplos abaixo
# ---------------------------------------------------------------------------

# Simula um comando que falha nas primeiras N chamadas e depois tem sucesso.
# Útil para testar o comportamento de retry sem depender de rede real.
_contador_falhas=0
comando_instavel() {
    local falhas_antes_de_sucesso="${1:-2}"
    _contador_falhas=$(( _contador_falhas + 1 ))
    if [ "$_contador_falhas" -le "$falhas_antes_de_sucesso" ]; then
        return 1  # falha
    fi
    _contador_falhas=0
    return 0  # sucesso
}

# ---------------------------------------------------------------------------
# Exemplo 1: tentar — retry com delay fixo, sem spinner
#
# Ideal quando o script roda sem terminal interativo (cron, CI/CD),
# onde animações não fazem sentido e o log precisa ser legível em texto puro.
#
# Sintaxe: tentar <tentativas> <delay_segundos> <comando...>
# ---------------------------------------------------------------------------

info "=== Exemplo 1: tentar ==="

# Tenta um comando que falha 2 vezes antes de ter sucesso.
# Saída esperada:
#   Tentativa 1/3 falhou. Aguardando 2s...
#   Tentativa 2/3 falhou. Aguardando 2s...
#   (sucesso na 3ª tentativa, função retorna 0)
_contador_falhas=0
if tentar 3 2 comando_instavel 2; then
    sucesso "Comando concluído com sucesso."
else
    erro "Comando falhou em todas as tentativas."
fi

# Tenta um comando que sempre falha para demonstrar a mensagem de esgotamento.
# Saída esperada:
#   Tentativa 1/3 falhou. Aguardando 1s...
#   Tentativa 2/3 falhou. Aguardando 1s...
#   Tentativa 3/3 falhou. Aguardando 1s...
#   Todas as 3 tentativas falharam: false
if tentar 3 1 false; then
    sucesso "Não deveria chegar aqui."
else
    alerta "Todas as tentativas falharam, como esperado."
fi

# ---------------------------------------------------------------------------
# Exemplo 2: tentar_com_backoff — retry com espera exponencial, sem spinner
#
# Ideal para comandos que podem sobrecarregar um serviço em recuperação.
# O delay dobra a cada falha: 2s → 4s → 8s → ...
# Use quando o serviço remoto precisa de tempo crescente para se estabilizar.
#
# Sintaxe: tentar_com_backoff <tentativas> <delay_inicial_segundos> <comando...>
# ---------------------------------------------------------------------------

info "=== Exemplo 2: tentar_com_backoff ==="

# Tenta um comando com backoff exponencial.
# Com delay inicial de 1s e 3 tentativas, os waits serão: 1s, 2s, 4s.
# Saída esperada:
#   Tentativa 1/3 falhou. Aguardando 1s (backoff exponencial)...
#   Tentativa 2/3 falhou. Aguardando 2s (backoff exponencial)...
#   (sucesso na 3ª tentativa)
_contador_falhas=0
if tentar_com_backoff 3 1 comando_instavel 2; then
    sucesso "Comando concluído com sucesso após backoff."
else
    erro "Comando falhou em todas as tentativas."
fi

# ---------------------------------------------------------------------------
# Exemplo 3: tentar_spinner — retry com delay fixo e spinner visual
#
# Mesma lógica de tentar, mas exibe animação enquanto o comando executa
# e durante o período de espera entre tentativas.
# ATENÇÃO: a saída do comando é descartada para não quebrar o spinner.
# Use quando o feedback visual é mais importante que ver o output do comando.
#
# Sintaxe: tentar_spinner <tentativas> <delay_segundos> <comando...>
# ---------------------------------------------------------------------------

info "=== Exemplo 3: tentar_spinner ==="

# O spinner anima enquanto o comando roda e enquanto aguarda entre tentativas.
# Saída esperada no terminal:
#   [⠙] Tentativa 1/3: comando_instavel 2   (animando)
#   [✗] Tentativa 1/3 falhou.
#   [⠹] Aguardando 2s antes da próxima tentativa...  (animando)
#   [⠸] Tentativa 2/3: comando_instavel 2   (animando)
#   [✗] Tentativa 2/3 falhou.
#   [⠼] Aguardando 2s antes da próxima tentativa...  (animando)
#   [⠴] Tentativa 3/3: comando_instavel 2   (animando)
#   [✓] Concluído na tentativa 3/3.
_contador_falhas=0
if tentar_spinner 3 2 comando_instavel 2; then
    sucesso "Comando concluído com spinner."
else
    erro "Comando falhou em todas as tentativas."
fi

# Exemplo com um comando real de rede (requer conectividade).
# Tenta fazer ping 3 vezes com 3s de espera entre tentativas.
# Substitua o host por um que faça sentido no seu ambiente.
# tentar_spinner 3 3 ping -c 1 -W 2 8.8.8.8

# ---------------------------------------------------------------------------
# Exemplo 4: tentar_backoff_spinner — retry com backoff exponencial e spinner
#
# Combina a espera exponencial do tentar_com_backoff com o spinner visual.
# Ideal para operações de rede onde se quer feedback visual e evitar
# sobrecarga em serviços instáveis.
#
# Sintaxe: tentar_backoff_spinner <tentativas> <delay_inicial_segundos> <comando...>
# ---------------------------------------------------------------------------

info "=== Exemplo 4: tentar_backoff_spinner ==="

# Com delay inicial de 1s e 4 tentativas, os waits animados serão: 1s, 2s, 4s.
# Saída esperada no terminal:
#   [⠙] Tentativa 1/4: comando_instavel 3   (animando)
#   [✗] Tentativa 1/4 falhou.
#   [⠹] Aguardando 1s (backoff exponencial)...  (animando)
#   [⠸] Tentativa 2/4: comando_instavel 3   (animando)
#   [✗] Tentativa 2/4 falhou.
#   [⠼] Aguardando 2s (backoff exponencial)...  (animando)
#   [⠴] Tentativa 3/4: comando_instavel 3   (animando)
#   [✗] Tentativa 3/4 falhou.
#   [⠦] Aguardando 4s (backoff exponencial)...  (animando)
#   [⠧] Tentativa 4/4: comando_instavel 3   (animando)
#   [✓] Concluído na tentativa 4/4.
_contador_falhas=0
if tentar_backoff_spinner 4 1 comando_instavel 3; then
    sucesso "Comando concluído com backoff e spinner."
else
    erro "Comando falhou em todas as tentativas."
fi

# ---------------------------------------------------------------------------
# Resumo de quando usar cada função
#
#   tentar              → scripts não-interativos (cron, CI/CD), output legível
#   tentar_com_backoff  → serviços instáveis, evitar sobrecarga, sem terminal
#   tentar_spinner      → scripts interativos, delay fixo, feedback visual
#   tentar_backoff_spinner → scripts interativos, serviços em recuperação
# ---------------------------------------------------------------------------
