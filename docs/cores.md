# cores — Colorização de texto com códigos ANSI

**Arquivo:** `cores.sh`
**Dependências:** nenhuma

Permite exibir texto colorido no terminal usando códigos de escape ANSI, compatíveis com a maioria dos terminais modernos (VT100).

## Referência rápida

| Função | Cor | Quebra de linha | Uso |
|--------|-----|----------------|-----|
| `vermelho` | Vermelho | Sim | Mensagens de erro standalone |
| `verde` | Verde | Sim | Mensagens de sucesso standalone |
| `amarelo` | Amarelo | Sim | Avisos standalone |
| `azul` | Azul | Sim | Informações standalone |
| `cor_vermelho` | Vermelho | Não | Uso inline com `printf` ou subshell |
| `cor_verde` | Verde | Não | Uso inline com `printf` ou subshell |
| `cor_amarelo` | Amarelo | Não | Uso inline com `printf` ou subshell |
| `cor_azul` | Azul | Não | Uso inline com `printf` ou subshell |

## Funções com quebra de linha (standalone)

Usadas quando a cor ocupa a linha inteira:

```bash
vermelho "mensagem de erro"
verde    "operação concluída"
amarelo  "atenção: verifique as configurações"
azul     "informação adicional"
```

## Funções inline (sem quebra de linha)

Usadas para colorir parte de uma linha dentro de `printf` ou subshell:

```bash
printf "Resultado: %s e %s\n" "$(cor_verde OK)" "$(cor_vermelho FALHOU)"

status="[$(cor_azul INFO)] Sistema iniciado"
echo "$status"

printf "[%s] Deploy concluído em %s\n" "$(cor_verde ✓)" "$(cor_azul produção)"
```

## Observação sobre terminais sem suporte a cores

Os códigos ANSI serão exibidos como texto literal em terminais sem suporte (ex: ao redirecionar saída para arquivo). Para uso em scripts que podem ter saída redirecionada, verifique `[ -t 1 ]` antes de colorir:

```bash
if [ -t 1 ]; then
    verde "Sucesso"
else
    echo "Sucesso"
fi
```
