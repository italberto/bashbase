# inputs — Coleta interativa de dados do usuário

**Arquivo:** `inputs.sh`
**Dependências:** `validau.sh`, `sinais.sh`

Fornece wrappers interativos para os tipos mais comuns de entrada do usuário, com validação automática e suporte a menus navegáveis pelo teclado. Os valores coletados são armazenados em variáveis passadas por nome (passagem por referência via `printf -v`).

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `pergunta` | Lê uma linha de texto livre |
| `pergunta_sim_nao` | Lê resposta s/n, armazena `"1"`/`""` |
| `pergunta_senha` | Lê senha sem ecoar no terminal |
| `pergunta_numero` | Lê número inteiro com validação de range |
| `pergunta_ip` | Lê e valida endereço IPv4 |
| `pergunta_email` | Lê e valida endereço de e-mail |
| `pergunta_url` | Lê e valida URL (http/https/ftp) |
| `pergunta_porta` | Lê e valida número de porta (1-65535) |
| `pergunta_escolha` | Menu numerado com `select` do Bash |
| `menu_interativo` | Menu navegável com setas e Enter/ESC |
| `barra_de_progresso` | Barra de progresso em linha |

## Padrão de uso

Todas as funções `pergunta_*` recebem a pergunta como primeiro argumento e o **nome da variável de destino** como segundo. O valor coletado é armazenado na variável via `printf -v` (sem subshell).

```bash
pergunta "Qual seu nome?" nome
echo "Olá, $nome"
```

## Funções

### `pergunta <pergunta> <var>`

Lê uma linha de texto livre sem validação.

```bash
pergunta "Qual o nome do servidor?" servidor
echo "Configurando $servidor..."
```

---

### `pergunta_sim_nao <pergunta> <var>`

Lê `s` ou `n` (case-insensitive) e armazena `"1"` (sim) ou `""` (não). Repete até obter resposta válida.

```bash
pergunta_sim_nao "Deseja sobrescrever o arquivo?" confirma
[ "$confirma" = "1" ] && cp origem destino
```

---

### `pergunta_senha <pergunta> <var>`

Lê a senha sem exibir os caracteres digitados (`read -s`). Imprime uma quebra de linha após a leitura.

```bash
pergunta_senha "Senha do banco de dados" db_pass
```

---

### `pergunta_numero <pergunta> <var> [min] [max]`

Lê um número inteiro com validação de range opcional. Repete até obter valor válido.

```bash
pergunta_numero "Quantas réplicas?" replicas
pergunta_numero "Porta do serviço" porta 1 65535
pergunta_numero "Timeout em segundos" timeout 1
```

---

### `pergunta_ip <pergunta> <var>`

Lê um endereço IPv4 e valida via `valida_ip`. Repete até obter valor válido.

```bash
pergunta_ip "IP do servidor de banco de dados" db_host
echo "Conectando em $db_host..."
```

---

### `pergunta_email <pergunta> <var>`

Lê um endereço de e-mail e valida via `valida_email`. Repete até obter valor válido.

```bash
pergunta_email "E-mail do administrador" admin_email
```

---

### `pergunta_url <pergunta> <var>`

Lê uma URL e valida via `valida_url` (aceita http, https e ftp). Repete até obter valor válido.

```bash
pergunta_url "URL da API" api_url
```

---

### `pergunta_porta <pergunta> <var>`

Lê um número de porta (1-65535) e valida via `valida_porta`. Repete até obter valor válido.

```bash
pergunta_porta "Porta de escuta" porta_app
```

---

### `pergunta_escolha <pergunta> <var> <op1> <op2>...`

Exibe um menu numerado usando o `select` do Bash. Repete até o usuário escolher uma opção válida.

```bash
pergunta_escolha "Ambiente de deploy" ambiente "desenvolvimento" "homologação" "produção"
echo "Fazendo deploy em: $ambiente"
```

---

### `menu_interativo <título> <var> <op1> <op2>...`

Exibe um menu navegável com setas ↑↓ e confirmação com Enter. O cursor é ocultado durante a navegação e restaurado ao sair (inclusive em caso de Ctrl+C, via `sinais.sh`).

**Retorno:** 0 ao confirmar (Enter), 1 ao cancelar (ESC).

```bash
menu_interativo "Selecione o ambiente:" ambiente \
    "Desenvolvimento" \
    "Homologação" \
    "Produção"

if [ $? -eq 0 ]; then
    echo "Ambiente selecionado: $ambiente"
else
    echo "Operação cancelada."
fi
```

---

### `barra_de_progresso <atual> <total> [largura] [mensagem]`

Exibe uma barra de progresso em linha no terminal, atualizando em tempo real via `\r`. Ao atingir 100%, imprime uma quebra de linha. A largura padrão é 40 caracteres.

```bash
total=100
for i in $(seq 1 $total); do
    # ... processar item $i ...
    barra_de_progresso $i $total 40 "Processando arquivos..."
done
```

Saída típica:
```
[████████████████████░░░░░░░░░░░░░░░░░░░]  50% Processando arquivos...
```
