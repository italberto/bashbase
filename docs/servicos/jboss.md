# jboss — Operações de alto nível para JBoss/WildFly

**Arquivo:** `lib/servicos/jboss.sh`
**Camada:** serviços
**Dependências:** `redes.sh`, `alerta.sh`, `systemu.sh`

Fornece funções para verificar disponibilidade, inspecionar deployments e consultar o estado de instâncias JBoss/WildFly. As funções aceitam `host` e `porta` opcionais; quando omitidos, usam `localhost` com as portas padrão (`8080` para HTTP, `9990` para management).

Funções de management requerem `curl`. Para operações autenticadas, defina `JBOSS_MGMT_USER` e `JBOSS_MGMT_PASS` antes de chamar as funções.

## Referência rápida

| Função | Porta padrão | Descrição |
|--------|-------------|-----------|
| `jboss_esta_rodando [host] [porta]` | 8080 | Verifica se o servidor está acessível |
| `jboss_management_disponivel [host] [porta]` | 9990 | Verifica se a porta de management está acessível |
| `jboss_deployment_ativo <app> [host] [porta]` | 9990 | Verifica se um deployment está no estado OK |
| `jboss_listar_deployments [host] [porta]` | 9990 | Lista deployments e seus estados |
| `jboss_checar_saude [host] [porta]` | 9990 | Verifica o estado geral do servidor |
| `jboss_versao [host] [porta]` | 9990 | Retorna a versão do servidor |

## Funções

### `jboss_esta_rodando [host] [porta]`

Verifica se o JBoss está aceitando conexões na porta HTTP. Não requer `curl`.

```bash
jboss_esta_rodando || { erro "JBoss fora do ar"; exit 1; }
jboss_esta_rodando "app.prod.local"
jboss_esta_rodando "app.prod.local" 8180   # porta não padrão
```

---

### `jboss_management_disponivel [host] [porta]`

Verifica se a porta de management (API HTTP de administração) está acessível.

```bash
jboss_management_disponivel || alerta "Management inacessível"
jboss_management_disponivel "app.prod.local" 19990
```

---

### `jboss_deployment_ativo <app> [host] [porta]`

Verifica se um deployment está registrado e com status `OK`. O nome deve incluir a extensão (`.war`, `.jar`, `.ear`).

```bash
jboss_deployment_ativo "minha-app.war" || { erro "Deploy inativo"; exit 1; }
jboss_deployment_ativo "api.war" "app.prod.local"
```

---

### `jboss_listar_deployments [host] [porta]`

Lista todos os deployments e seus estados no formato `nome: estado`.

```bash
jboss_listar_deployments
# minha-app.war: OK
# legado.ear: FAILED

jboss_listar_deployments "app.prod.local"
```

---

### `jboss_checar_saude [host] [porta]`

Verifica o atributo `server-state` via management API. Retorna 0 apenas se o estado for `running`.

```bash
jboss_checar_saude || { erro "JBoss não está running"; exit 1; }
jboss_checar_saude "app.prod.local" && sucesso "Servidor saudável"
```

---

### `jboss_versao [host] [porta]`

Retorna o valor do atributo `product-version` do servidor.

```bash
versao=$(jboss_versao)
info "WildFly $versao"

jboss_versao "app.prod.local"
```

## Autenticação

Para instâncias com autenticação na porta de management:

```bash
export JBOSS_MGMT_USER=admin
export JBOSS_MGMT_PASS=senha_segura

jboss_checar_saude "app.prod.local"
jboss_deployment_ativo "minha-app.war" "app.prod.local"
```

A autenticação usa Digest Auth (padrão do WildFly) via `curl --digest`.
