# systemu — Utilitários gerais de sistema

**Arquivo:** `systemu.sh`
**Dependências:** nenhuma

Fornece verificações de privilégios, detecção de programas instalados e funções de encerramento padronizadas para scripts de automação. É o módulo base sem dependências, usado por vários outros módulos.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `sys_e_root` | Verifica se o script está sendo executado como root |
| `sys_programa_esta_instalado` | Verifica se um programa está disponível no PATH |
| `sys_finaliza_ok` | Encerra o script com código de saída 0 (sucesso) |
| `sys_finaliza_erro` | Encerra o script com código de saída 1 (erro) |

## Funções

### `sys_e_root`

Verifica se o EUID do processo atual é 0 (root).

**Retorno:** 0 se for root, 1 caso contrário.

```bash
sys_e_root || { erro "Execute como root"; exit 1; }

if sys_e_root; then
    echo "Executando com privilégios de root"
fi
```

---

### `sys_programa_esta_instalado <nome>`

Verifica se um programa está instalado e acessível no PATH usando `command -v`.

**Retorno:** 0 se encontrado, 1 caso contrário.

```bash
sys_programa_esta_instalado "curl"   || { erro "curl não encontrado"; exit 1; }
sys_programa_esta_instalado "docker" && echo "Docker disponível"

# Instalação condicional:
sys_programa_esta_instalado "jq" || instala_pacote "jq"
```

---

### `sys_finaliza_ok`

Encerra o script com código de saída 0. Equivalente a `exit 0`.

```bash
sucesso "Script concluído com sucesso."
sys_finaliza_ok
```

---

### `sys_finaliza_erro`

Encerra o script com código de saída 1. Equivalente a `exit 1`.

```bash
erro "Configuração inválida. Verifique os parâmetros."
sys_finaliza_erro
```
