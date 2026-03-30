# configu — Leitura e escrita de arquivos de configuração

**Arquivo:** `configu.sh`
**Dependências:** nenhuma

Trabalha com arquivos no formato `CHAVE=valor`, compatível com o padrão `.env`. Suporta valores com ou sem aspas e ignora comentários e linhas em branco.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `config_ler` | Lê o valor de uma chave |
| `config_existe` | Verifica se uma chave existe |
| `config_escrever` | Cria ou atualiza uma chave |
| `config_remover` | Remove uma chave do arquivo |
| `config_carregar` | Exporta todas as chaves como variáveis de ambiente |

## Formato suportado

```ini
# Comentário ignorado
DB_HOST=localhost
DB_PORT=5432
DB_NAME="meu_banco"
DB_PASS='senha123'
```

## Funções

### `config_ler <arquivo> <chave>`

Lê e retorna o valor de uma chave. Remove aspas simples e duplas ao redor do valor, se presentes.

**Retorno:** 1 se o arquivo não existir ou a chave não for encontrada.

**Exemplo:**
```bash
host=$(config_ler /etc/app/config.env DB_HOST)
porta=$(config_ler /etc/app/config.env DB_PORT)
echo "Conectando em $host:$porta"
```

---

### `config_existe <arquivo> <chave>`

Retorna 0 se a chave existir no arquivo, 1 caso contrário. Não lê o valor.

**Retorno:** 1 se o arquivo não existir.

**Exemplo:**
```bash
config_existe /etc/app.conf "DATABASE_URL" || {
    erro "Configuração DATABASE_URL não encontrada"
    exit 1
}
```

---

### `config_escrever <arquivo> <chave> <valor>`

Cria ou atualiza uma chave no arquivo. Se a chave já existir, seu valor é substituído na mesma linha. Se não existir, é adicionada ao final. O arquivo é criado automaticamente se não existir.

**Exemplo:**
```bash
config_escrever /etc/app/config.env DB_PORT 5432
config_escrever /etc/app/config.env DEBUG true
```

---

### `config_remover <arquivo> <chave>`

Remove uma chave e seu valor do arquivo.

**Retorno:** 1 se o arquivo não existir.

**Exemplo:**
```bash
config_remover /etc/app/config.env DB_PASSWORD
```

---

### `config_carregar <arquivo>`

Importa todas as chaves do arquivo como variáveis de ambiente exportadas (`export`). Linhas em branco e comentários (iniciados com `#`) são ignorados. Aspas simples e duplas ao redor dos valores são removidas automaticamente.

**Retorno:** 1 se o arquivo não existir.

**Exemplo:**
```bash
config_carregar /etc/app/config.env
echo "$DB_HOST"   # variável agora disponível no script e em processos filhos
```

## Exemplo completo

```bash
source "$BASHBASE/configu.sh"
source "$BASHBASE/alerta.sh"

CONFIG=/etc/meu_app/config.env

config_existe "$CONFIG" DB_HOST || {
    erro "Configuração incompleta: DB_HOST não definido em $CONFIG"
    exit 1
}

config_carregar "$CONFIG"
info "Conectando ao banco em $DB_HOST:${DB_PORT:-5432}"
```
