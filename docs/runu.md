# runu — Execução de comandos com spinner e timeout

**Arquivo:** `runu.sh`
**Dependências:** `spinner.sh`

Executa comandos em background enquanto exibe um spinner de progresso. Ao término, exibe o resultado com ícone colorido (✓ sucesso / ✗ falha). A saída do comando é redirecionada para `/dev/null` para não interferir no layout da animação.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `executar` | Executa comando local com spinner |
| `executar_remoto` | Executa comando remoto via SSH com spinner |
| `executar_com_timeout` | Executa comando com limite máximo de tempo |

## Funções

### `executar <mensagem> <comando>`

Executa um comando shell em background exibindo um spinner de progresso. Ao concluir, exibe mensagem de sucesso (verde) ou falha (vermelho) com o código de saída. A saída do comando (stdout e stderr) é descartada.

```bash
executar "Instalando dependências" "apt install -y curl jq"
executar "Sincronizando arquivos"  "rsync -av origem/ destino/"
executar "Reiniciando serviço"     "systemctl restart nginx"
```

**Saída:**
```
[✓] Instalando dependências concluído!
[✗] Sincronizando arquivos falhou (Erro: 23)
```

---

### `executar_remoto <host> <mensagem> <comando>`

Executa um comando em um host remoto via SSH, exibindo um spinner. Usa `BatchMode=yes` para não solicitar senhas e `ConnectTimeout=10` para evitar travamentos em hosts inacessíveis. A saída do comando remoto é descartada.

```bash
executar_remoto "usuario@192.168.1.10" "Reiniciando nginx"  "systemctl restart nginx"
executar_remoto "deploy@prod-01"       "Atualizando código" "cd /app && git pull"
```

---

### `executar_com_timeout <segundos> <comando...>`

Executa um comando com limite máximo de tempo usando `timeout(1)` do GNU coreutils. Se o tempo for excedido, imprime uma mensagem no stderr e retorna o código `124` (código padrão do `timeout`).

**Retorno:** 0 em sucesso, código de saída do comando em falha, 124 em timeout.

```bash
executar_com_timeout 30 curl -s https://api.exemplo.com
executar_com_timeout 10 rsync -av origem/ destino/

if ! executar_com_timeout 60 ./processo_lento.sh; then
    [ $? -eq 124 ] && erro "Timeout atingido" || erro "Processo falhou"
fi
```

## Exemplo completo

```bash
source "$BASHBASE/runu.sh"
source "$BASHBASE/alerta.sh"

executar "Atualizando lista de pacotes" "apt update" || {
    erro "Falha ao atualizar pacotes"
    exit 1
}

executar "Instalando dependências" "apt install -y nginx certbot" || exit 1

executar_remoto "app@192.168.1.20" "Reiniciando aplicação" "systemctl restart minha-app"

sucesso "Deploy concluído!"
```
