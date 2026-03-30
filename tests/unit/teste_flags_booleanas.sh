#!/bin/bash
# teste_flags_booleanas.sh
# Testes automatizados para demonstrar inconsistências em flags booleanas

set -u  # Erro se variável não definida

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTES_PASSADOS=0
TESTES_FALHADOS=0

# ═══════════════════════════════════════════════════════════════════════════
# Funções de teste
# ═══════════════════════════════════════════════════════════════════════════

test_verdadeiro() {
    local titulo="$1"
    local condicao="$2"
    
    if eval "$condicao"; then
        echo -e "${GREEN}✅ PASSOU${NC} - $titulo"
        ((TESTES_PASSADOS++))
    else
        echo -e "${RED}❌ FALHOU${NC} - $titulo"
        ((TESTES_FALHADOS++))
    fi
}

test_falso() {
    local titulo="$1"
    local condicao="$2"
    
    if ! eval "$condicao"; then
        echo -e "${GREEN}✅ PASSOU${NC} - $titulo"
        ((TESTES_PASSADOS++))
    else
        echo -e "${RED}❌ FALHOU${NC} - $titulo"
        ((TESTES_FALHADOS++))
    fi
}

expect_value() {
    local titulo="$1"
    local variavel="$2"
    local valor_esperado="$3"
    
    local valor_real="${!variavel}"
    
    if [ "$valor_real" = "$valor_esperado" ]; then
        echo -e "${GREEN}✅ PASSOU${NC} - $titulo (valor='$valor_real')"
        ((TESTES_PASSADOS++))
    else
        echo -e "${RED}❌ FALHOU${NC} - $titulo (esperado='$valor_esperado', obtido='$valor_real')"
        ((TESTES_FALHADOS++))
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# TESTES
# ═══════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          TESTES: Flags Booleanas Ambíguas                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 1]${NC} Padrão argsu.sh: '1' para verdadeiro"
echo "─────────────────────────────────────────────────────────────────────"

VERBOSE="1"
test_verdadeiro "VERBOSE='1' é verdadeiro" '[ "$VERBOSE" = "1" ]'
test_falso "VERBOSE='1' é falso" '[ "$VERBOSE" = "" ]'

VERBOSE=""
test_falso "VERBOSE='' (vazio) é verdadeiro" '[ "$VERBOSE" = "1" ]'
test_verdadeiro "VERBOSE='' (vazio) é falso" '[ "$VERBOSE" = "" ]'
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 2]${NC} Padrão inputs.pergunta_sim_nao: 'true'/'false'"
echo "─────────────────────────────────────────────────────────────────────"

RESPOSTA_SIM="true"
RESPOSTA_NAO="false"

test_verdadeiro "RESPOSTA_SIM='true' com verificação literal" '[ "$RESPOSTA_SIM" = "true" ]'
test_falso "RESPOSTA_SIM='true' com verificação argsu.sh style" '[ "$RESPOSTA_SIM" = "1" ]'

test_verdadeiro "RESPOSTA_NAO='false' com verificação literal" '[ "$RESPOSTA_NAO" = "false" ]'
test_falso "RESPOSTA_NAO='false' é vazio" '[ "$RESPOSTA_NAO" = "" ]'
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 3]${NC} Incompatibilidade: argsu.sh vs inputs.pergunta_sim_nao"
echo "─────────────────────────────────────────────────────────────────────"

# Simular código que espera padrão argsu.sh
check_verbose() {
    [ "${VERBOSE:-}" = "1" ] && return 0 || return 1
}

VERBOSE="1"
test_verdadeiro "argsu style (VERBOSE='1') com check_verbose()" 'check_verbose'

VERBOSE="true"  # Simular resposta de pergunta_sim_nao
test_falso "inputs style (VERBOSE='true') com check_verbose() → FALHA!" 'check_verbose'

VERBOSE=""
test_falso "argsu style vazio com check_verbose()" 'check_verbose'

VERBOSE="false"
test_falso "inputs style (VERBOSE='false') com check_verbose()" 'check_verbose'
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 4]${NC} DEBUG: padrão em alerta.sh"
echo "─────────────────────────────────────────────────────────────────────"

# Simular verificação de alerta.sh:119
check_debug() {
    [ "${DEBUG:-0}" = "1" ] && return 0 || return 1
}

DEBUG="1"
test_verdadeiro "DEBUG='1' ativa debug" 'check_debug'

# Problema: documentação menciona DEBUG=true
DEBUG="true"
test_falso "DEBUG='true' NÃO ativa debug (problema!)" 'check_debug'

unset DEBUG
test_falso "DEBUG não definido não ativa debug" 'check_debug'

DEBUG="0"
test_falso "DEBUG='0' não ativa debug" 'check_debug'
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 5]${NC} Padrão logu.sh: valores numéricos (0-3)"
echo "─────────────────────────────────────────────────────────────────────"

# Constantes
readonly _LOG_DEBUG=0
readonly _LOG_INFO=1
_LOG_NIVEL_MINIMO=0

# Teste de comparação numérica
test_verdadeiro "_LOG_DEBUG (0) < _LOG_INFO (1)" '[ $_LOG_DEBUG -lt $_LOG_INFO ]'
test_verdadeiro "_LOG_DEBUG (0) é igual a 0" '[ $_LOG_DEBUG -eq 0 ]'
test_falso "_LOG_INFO (1) é igual a 0" '[ $_LOG_INFO -eq 0 ]'

# Problema: usar string com -lt
test_falso "Comparar string '1' -lt número 2 (tipo mismatch)" '[ "true" -lt 2 ] 2>/dev/null'
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 6]${NC} Padrão Unix: Exit codes (return 0/1)"
echo "─────────────────────────────────────────────────────────────────────"

arquivo_existe() {
    [[ -f "$1" ]] && return 0 || return 1
}

# Criar arquivo temporário
TEST_FILE="/tmp/teste_booleano_$$"
touch "$TEST_FILE"

test_verdadeiro "arquivo_existe retorna 0 para arquivo existente" 'arquivo_existe "$TEST_FILE"'

rm -f "$TEST_FILE"
test_falso "arquivo_existe retorna 1 para arquivo nãoExistente" 'arquivo_existe "$TEST_FILE"'
echo

# ───────────────────────────────────────────────────────────────────────────
echo -e "${YELLOW}[TESTE 7]${NC} Solução: Função universal que aceita múltiplos padrões"
echo "─────────────────────────────────────────────────────────────────────"

eh_verdadeiro() {
    local valor="$1"
    case "$valor" in
        1|"1"|true|"true"|yes|"yes"|sim|"sim"|on|"on") return 0 ;;
        0|"0"|false|"false"|no|"no"|não|"não"|off|"off"|"") return 1 ;;
        *) return 2 ;; # Valor desconhecido
    esac
}

test_verdadeiro "eh_verdadeiro '1'" 'eh_verdadeiro "1"'
test_verdadeiro "eh_verdadeiro 'true'" 'eh_verdadeiro "true"'
test_verdadeiro "eh_verdadeiro 'sim'" 'eh_verdadeiro "sim"'
test_verdadeiro "eh_verdadeiro 'yes'" 'eh_verdadeiro "yes"'

test_falso "eh_verdadeiro '0'" 'eh_verdadeiro "0"'
test_falso "eh_verdadeiro 'false'" 'eh_verdadeiro "false"'
test_falso "eh_verdadeiro 'não'" 'eh_verdadeiro "não"'
test_falso "eh_verdadeiro ''" 'eh_verdadeiro ""'

# Valor inválido
eh_verdadeiro "talvez" && false || RET=$?
test_verdadeiro "eh_verdadeiro 'talvez' retorna 2 (desconhecido)" '[ $RET -eq 2 ]'
echo

# ═══════════════════════════════════════════════════════════════════════════
# Resumo
# ═══════════════════════════════════════════════════════════════════════════

echo
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         RESUMO DOS TESTES                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo

TOTAL=$((TESTES_PASSADOS + TESTES_FALHADOS))
TAXA_SUCESSO=$((TESTES_PASSADOS * 100 / TOTAL))

echo "Testes executed: $TOTAL"
echo "Passed: $TESTES_PASSADOS"
echo "Failed: $TESTES_FALHADOS"
echo "Success rate: $TAXA_SUCESSO%"
echo

if [ $TESTES_FALHADOS -gt 0 ]; then
    echo -e "${RED}❌ Inconsistências detectadas!${NC}"
    echo
    echo "Problemas encontrados:"
    echo "1. inputs.pergunta_sim_nao() retorna 'true'/'false' (não '1'/'')"
    echo "2. alerta.sh não reconhece DEBUG='true'"
    echo "3. Misturar padrões causa falhas silenciosas"
    echo
    exit 1
else
    echo -e "${GREEN}✅ Sem inconsistências detectadas!${NC}"
    exit 0
fi
