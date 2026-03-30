# redes — Primitivos de diagnóstico de rede

**Arquivo:** `lib/redes.sh`
**Dependências:** `systemu.sh`, `alerta.sh`

Fornece verificações de baixo nível sobre infraestrutura de rede: conectividade com a internet, resolução DNS, interfaces, gateway padrão, Wi-Fi, Ethernet e disponibilidade de portas TCP. Não conhece serviços específicos — para isso, use `lib/servicos/conectividade.sh`.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `con_checar_internet` | Verifica conectividade com a internet |
| `con_checar_dns` | Verifica resolução de nomes DNS |
| `con_checar_porta <host> <porta> [timeout]` | Verifica se uma porta TCP está aberta |
| `con_checar_interface <interface>` | Verifica se uma interface de rede existe |
| `con_checar_gateway` | Verifica se há gateway padrão configurado |
| `con_checar_wifi` | Verifica se há conexão Wi-Fi ativa |
| `con_checar_ethernet` | Verifica se há conexão Ethernet ativa |
| `con_lista_enderecos_ip` | Lista os endereços IP de todas as interfaces |

## Funções

### `con_checar_internet`

Tenta `google.com` via ping; se falhar, tenta `8.8.8.8`. Retorna 0 se qualquer ping tiver sucesso.

```bash
con_checar_internet || { erro "Sem acesso à internet"; exit 1; }
```

---

### `con_checar_dns`

Tenta resolver `google.com` usando `host`, `dig` ou `nslookup` (nesta ordem). Retorna 0 se qualquer ferramenta confirmar a resolução.

```bash
con_checar_dns || alerta "Resolução DNS falhou"
```

---

### `con_checar_porta <host> <porta> [timeout]`

Verifica se uma porta TCP está aberta. Usa `/dev/tcp` (built-in do Bash) como método primário e `nc` como fallback. O timeout padrão é 3 segundos.

```bash
con_checar_porta api.exemplo.com 443 5
con_checar_porta localhost 5432 && info "PostgreSQL acessível"
```

---

### `con_checar_interface <interface>`

Verifica se uma interface de rede existe no sistema via `ip link show`.

```bash
con_checar_interface eth0 || alerta "Interface eth0 não encontrada"
con_checar_interface wlan0 && info "Interface Wi-Fi presente"
```

---

### `con_checar_gateway`

Verifica se há uma rota padrão configurada via `ip route`.

```bash
con_checar_gateway || { erro "Sem gateway padrão"; exit 1; }
```

---

### `con_checar_wifi`

Verifica se há conexão Wi-Fi ativa. Usa `nmcli` como método primário; cai para `iwconfig` como fallback.

```bash
con_checar_wifi && info "Wi-Fi conectado"
```

---

### `con_checar_ethernet`

Verifica se há conexão Ethernet ativa. Usa `nmcli` como método primário; cai para `ethtool` como fallback.

```bash
con_checar_ethernet && info "Ethernet conectada"
con_checar_ethernet || alerta "Ethernet desconectada"
```

---

### `con_lista_enderecos_ip`

Lista os endereços IPv4 de todas as interfaces no formato `INTERFACE: IP/PREFIXO`.

```bash
con_lista_enderecos_ip
# eth0: 192.168.1.100/24
# lo: 127.0.0.1/8
```
