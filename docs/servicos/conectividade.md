# conectividade — Verificação de disponibilidade de serviços de rede

**Arquivo:** `lib/servicos/conectividade.sh`
**Camada:** serviços
**Dependências:** `redes.sh`

Fornece funções de alto nível para testar se serviços padrão de rede estão acessíveis em um host, verificando suas portas convencionais. Cada função aceita um host opcional; quando omitido, verifica o `localhost`.

Para primitivos de rede (checar portas genéricas, interfaces, gateway), use `lib/redes.sh`.

## Referência rápida

| Função | Porta | Protocolo |
|--------|-------|-----------|
| `con_ssh_disponivel [host]` | 22 | SSH |
| `con_http_disponivel [host]` | 80 | HTTP |
| `con_https_disponivel [host]` | 443 | HTTPS |
| `con_dns_disponivel [host]` | 53 | DNS |
| `con_smtp_disponivel [host]` | 25 | SMTP |
| `con_pop3_disponivel [host]` | 110 | POP3 |
| `con_imap_disponivel [host]` | 143 | IMAP |
| `con_ftp_disponivel [host]` | 21 | FTP |
| `con_smb_disponivel [host]` | 445 | SMB/CIFS |
| `con_rdp_disponivel [host]` | 3389 | RDP |
| `con_vpn_disponivel [host]` | 1194 | OpenVPN |

## Uso

```bash
source "$BASHBASE/lib/servicos/conectividade.sh"

con_ssh_disponivel                    # testa localhost:22
con_ssh_disponivel "192.168.1.10"     # testa host remoto:22
con_http_disponivel "api.exemplo.com"
con_https_disponivel "api.exemplo.com" && info "HTTPS disponível"

# Verificar múltiplos serviços
for fn in con_ssh_disponivel con_http_disponivel con_https_disponivel; do
    "$fn" && sucesso "$fn ok" || alerta "$fn indisponível"
done
```

## Observações

- Todas as funções retornam **0** se a porta estiver acessível e **1** caso contrário.
- O timeout de conexão é herdado do padrão de `con_checar_porta` (3 segundos).
- Verificam apenas se a porta está aberta; não validam o protocolo ou autenticação.
