# servicou — Gerenciamento de serviços systemd

**Arquivo:** `servicou.sh`
**Dependências:** `systemu.sh`, `alerta.sh`

Fornece wrappers para as operações mais comuns do `systemctl`. Verifica automaticamente se o systemd está disponível antes de cada operação, retornando 1 com mensagem de erro em sistemas que usam SysV, OpenRC ou similares.

## Referência rápida

| Função | Comando equivalente | Requer root |
|--------|--------------------|----|
| `servico_ativo` | `systemctl is-active` | Não |
| `servico_iniciar` | `systemctl start` | Sim |
| `servico_parar` | `systemctl stop` | Sim |
| `servico_reiniciar` | `systemctl restart` | Sim |
| `servico_habilitar` | `systemctl enable` | Sim |
| `servico_desabilitar` | `systemctl disable` | Sim |
| `servico_status` | `systemctl status` | Não |

## Funções

### `servico_ativo <nome>`

Verifica silenciosamente se um serviço está em execução. Ideal para uso em condicionais.

**Retorno:** 0 se ativo, 1 caso contrário.

```bash
servico_ativo "nginx" && echo "nginx está rodando"
servico_ativo "postgresql" || { erro "PostgreSQL não está ativo"; exit 1; }
```

---

### `servico_iniciar <nome>`

Inicia o serviço.

```bash
servico_iniciar "nginx"
servico_ativo "nginx" || servico_iniciar "nginx"
```

---

### `servico_parar <nome>`

Para o serviço em execução.

```bash
servico_parar "nginx"
```

---

### `servico_reiniciar <nome>`

Reinicia o serviço. Útil para aplicar novas configurações sem intervenção manual.

```bash
config_escrever /etc/nginx/conf.d/app.conf server_name "novo.exemplo.com"
servico_reiniciar "nginx"
```

---

### `servico_habilitar <nome>`

Habilita o início automático do serviço durante o boot. O serviço não é iniciado imediatamente.

```bash
servico_habilitar "nginx"
servico_habilitar "postgresql"
```

---

### `servico_desabilitar <nome>`

Desabilita o início automático no boot. O serviço não é parado imediatamente.

```bash
servico_desabilitar "bluetooth"
```

---

### `servico_status <nome>`

Exibe o status detalhado do serviço, incluindo logs recentes (saída do `systemctl status`).

```bash
servico_status "nginx"
servico_status "sshd"
```

## Exemplo: setup de serviço

```bash
source "$BASHBASE/servicou.sh"
source "$BASHBASE/systemu.sh"

sys_e_root || { erro "Execute como root"; exit 1; }

instala_pacote_quieto "nginx"

servico_habilitar "nginx"
servico_iniciar   "nginx"

servico_ativo "nginx" && sucesso "nginx iniciado com sucesso" \
                      || erro   "Falha ao iniciar nginx"
```
