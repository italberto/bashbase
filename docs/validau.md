# validau — Validação de IP, e-mail, URL, porta e variáveis

**Arquivo:** `validau.sh`
**Dependências:** nenhuma

Fornece validações para os tipos de dados mais comuns em scripts de automação. Todas as funções retornam **0** se o valor for válido e **1** caso contrário, seguindo a convenção de retorno do Bash para uso em condicionais.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `valida_ip` | Valida endereço IPv4 no formato A.B.C.D |
| `valida_email` | Valida formato de e-mail |
| `valida_url` | Valida URL com esquema http/https/ftp |
| `valida_porta` | Valida número de porta TCP/UDP (1-65535) |
| `variavel_obrigatoria` | Aborta o script se a variável não estiver definida |

## Funções

### `valida_ip <string>`

Verifica se a string é um endereço IPv4 válido no formato A.B.C.D, onde cada octeto está entre 0 e 255.

```bash
valida_ip "192.168.1.1"  # → 0 (válido)
valida_ip "256.0.0.1"    # → 1 (inválido)
valida_ip "10.0.0"       # → 1 (inválido)

valida_ip "$ip" || { erro "Endereço IP inválido: $ip"; exit 1; }
```

---

### `valida_email <string>`

Valida o formato de um endereço de e-mail. **Não valida a existência real do endereço.**

Aceita:
- Caracteres alfanuméricos e especiais `. _ % + -` antes do `@`
- Domínios com múltiplos níveis (`user@mail.co.uk`)
- Extensões de domínio com 2 ou mais caracteres

```bash
valida_email "user@exemplo.com"      # → 0 (válido)
valida_email "u.name+tag@mail.co.uk" # → 0 (válido)
valida_email "user@"                 # → 1 (sem domínio)
valida_email "nao-e-email"           # → 1 (sem @)

valida_email "$email" || { erro "E-mail inválido"; exit 1; }
```

---

### `valida_url <string>`

Verifica se a string é uma URL com esquema válido (`http`, `https` ou `ftp`) seguido de host e caminho opcional.

```bash
valida_url "https://exemplo.com/pagina"   # → 0 (válido)
valida_url "ftp://files.exemplo.com"      # → 0 (válido)
valida_url "exemplo.com"                  # → 1 (sem esquema)
valida_url "ssh://servidor"               # → 1 (esquema não suportado)

valida_url "$url" || { erro "URL inválida: $url"; exit 1; }
```

---

### `valida_porta <numero>`

Verifica se o valor é um número inteiro entre 1 e 65535.

```bash
valida_porta "8080"    # → 0 (válido)
valida_porta "0"       # → 1 (inválido)
valida_porta "65536"   # → 1 (inválido)
valida_porta "abc"     # → 1 (inválido)

valida_porta "$porta" || { erro "Porta inválida: $porta"; exit 1; }
```

---

### `variavel_obrigatoria <nome> [mensagem]`

Verifica se uma variável de ambiente está definida e não está vazia. Se não estiver, exibe uma mensagem de erro no stderr e **encerra o script com `exit 1`**.

Útil no início de scripts para verificar configurações críticas antes de iniciar operações que dependem delas.

```bash
variavel_obrigatoria DB_HOST
variavel_obrigatoria API_KEY "A chave da API é obrigatória para autenticar"
variavel_obrigatoria DEPLOY_ENV "Defina DEPLOY_ENV como 'staging' ou 'production'"
```

**Saída em caso de falha:**
```
ERRO: Variável de ambiente obrigatória não definida: DB_HOST
```

## Uso com inputs.sh

As funções `pergunta_ip`, `pergunta_email`, `pergunta_url` e `pergunta_porta` de `inputs.sh` usam as validações deste módulo internamente:

```bash
# inputs.sh usa validau.sh automaticamente
source "$BASHBASE/inputs.sh"

pergunta_ip "IP do servidor de banco" db_host
# repete até o usuário informar um IPv4 válido
```

## Exemplo: validação de configuração

```bash
source "$BASHBASE/validau.sh"
source "$BASHBASE/alerta.sh"

# Verificar variáveis obrigatórias logo no início do script
variavel_obrigatoria DB_HOST
variavel_obrigatoria DB_PORT
variavel_obrigatoria API_KEY

# Validar valores
valida_ip "$DB_HOST"   || { erro "DB_HOST não é um IP válido: $DB_HOST"; exit 1; }
valida_porta "$DB_PORT" || { erro "DB_PORT inválido: $DB_PORT"; exit 1; }
```
