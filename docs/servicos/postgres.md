# postgres — Operações de alto nível para PostgreSQL

**Arquivo:** `lib/servicos/postgres.sh`
**Camada:** serviços
**Dependências:** `redes.sh`, `alerta.sh`, `systemu.sh`

Fornece funções para verificar disponibilidade, inspecionar bancos de dados e executar queries em instâncias PostgreSQL. As funções aceitam `host` e `porta` opcionais; quando omitidos, usam `localhost` e a porta padrão `5432`.

Funções além de `pg_esta_rodando` requerem `psql` instalado. A autenticação usa as variáveis de ambiente padrão do PostgreSQL (`PGUSER`, `PGPASSWORD`, `PGHOST`, etc.) ou os parâmetros explícitos passados às funções.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `pg_esta_rodando [host] [porta]` | Verifica se o PostgreSQL está acessível na porta |
| `pg_banco_existe <banco> [host] [porta]` | Verifica se um banco de dados existe |
| `pg_executar_sql <sql> [banco] [host] [porta]` | Executa uma query e imprime o resultado |
| `pg_contar_conexoes [banco] [host] [porta]` | Conta conexões ativas |
| `pg_versao [host] [porta]` | Retorna a versão do servidor |
| `pg_checar_replicacao [host] [porta]` | Verifica se há réplicas conectadas |

## Funções

### `pg_esta_rodando [host] [porta]`

Verifica se o PostgreSQL está aceitando conexões TCP. Não requer `psql`.

```bash
pg_esta_rodando || { erro "PostgreSQL fora do ar"; exit 1; }
pg_esta_rodando "db.prod.local"
pg_esta_rodando "db.prod.local" 5433
```

---

### `pg_banco_existe <banco> [host] [porta]`

Consulta `pg_database` para verificar se o banco existe.

```bash
pg_banco_existe "producao" || { erro "Banco não encontrado"; exit 1; }
pg_banco_existe "homologacao" "db.local"
```

---

### `pg_executar_sql <sql> [banco] [host] [porta]`

Executa uma query SQL e imprime o resultado no stdout. Útil para automações que precisam extrair valores do banco.

```bash
pg_executar_sql "SELECT COUNT(*) FROM usuarios" "app"
total=$(pg_executar_sql "SELECT COUNT(*) FROM pedidos WHERE status='aberto'" "loja")
info "Pedidos abertos: $total"
```

---

### `pg_contar_conexoes [banco] [host] [porta]`

Conta conexões ativas via `pg_stat_activity`. Sem banco informado, conta todas as conexões da instância.

```bash
total=$(pg_contar_conexoes)
info "Conexões ativas: $total"

por_banco=$(pg_contar_conexoes "meubanco" "db.local")
[ "$por_banco" -gt 100 ] && alerta "Alto número de conexões: $por_banco"
```

---

### `pg_versao [host] [porta]`

Retorna a versão do servidor no formato `PostgreSQL X.Y`.

```bash
versao=$(pg_versao)
info "Servidor: $versao"

pg_versao "db.prod.local" 5433
```

---

### `pg_checar_replicacao [host] [porta]`

Verifica se há réplicas em modo `streaming` conectadas ao servidor primário. Requer acesso a `pg_stat_replication`.

```bash
pg_checar_replicacao || alerta "Nenhuma réplica ativa"
pg_checar_replicacao "db-primary.local" && sucesso "Replicação OK"
```

## Autenticação

As funções de query delegam ao `psql`, que respeita as variáveis de ambiente padrão:

```bash
export PGUSER=deploy
export PGPASSWORD=senha_segura

pg_banco_existe "producao"
pg_executar_sql "SELECT 1" "producao"
```
