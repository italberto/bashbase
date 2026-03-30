# pkgu — Abstração para gerenciadores de pacotes

**Arquivo:** `pkgu.sh`
**Dependências:** `distu.sh`

Detecta automaticamente o gerenciador de pacotes da distribuição em uso e executa a operação solicitada com o comando adequado. Suporta: `apt` (Debian/Ubuntu), `dnf` (Fedora), `pacman` (Arch), `yum` (Red Hat), `zypper` (SuSE), `emerge` (Gentoo) e `apk` (Alpine).

Todas as funções requerem **privilégios de root** (exceto `procura_pacote`).

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `atualizar_pacote` | Atualiza todos os pacotes do sistema |
| `instala_pacote` | Instala um pacote |
| `instala_pacote_quieto` | Instala um pacote sem saída no terminal |
| `remove_pacote` | Remove um pacote |
| `procura_pacote` | Busca pacotes pelo nome |
| `atualiza_pacote` | Atualiza um pacote específico |

## Funções

### `atualizar_pacote`

Atualiza a lista de pacotes e instala as atualizações disponíveis.

```bash
sys_e_root || { erro "Execute como root"; exit 1; }
atualizar_pacote
```

---

### `instala_pacote <nome> [silencioso]`

Instala um pacote. Se o segundo parâmetro for fornecido (qualquer valor), a instalação é silenciosa.

```bash
instala_pacote "curl"
instala_pacote "curl" 1   # instalação silenciosa
```

---

### `instala_pacote_quieto <nome>`

Wrapper conveniente para instalação silenciosa.

```bash
instala_pacote_quieto "jq"
instala_pacote_quieto "rsync"
```

---

### `remove_pacote <nome>`

Remove um pacote instalado.

```bash
remove_pacote "vim-minimal"
```

---

### `procura_pacote <nome>`

Busca pacotes disponíveis pelo nome ou descrição no repositório.

```bash
procura_pacote "nginx"
procura_pacote "python3"
```

---

### `atualiza_pacote <nome>`

Atualiza um pacote específico para a versão mais recente disponível.

```bash
atualiza_pacote "openssl"
```

## Distribuições suportadas

| Distribuição | Gerenciador |
|-------------|------------|
| Debian, Ubuntu | `apt` |
| Fedora | `dnf` |
| Arch Linux | `pacman` |
| Red Hat, CentOS | `yum` |
| SuSE Linux | `zypper` |
| Gentoo | `emerge` |
| Alpine Linux | `apk` |

## Exemplo de uso seguro

```bash
source "$BASHBASE/systemu.sh"
source "$BASHBASE/pkgu.sh"

sys_e_root || { erro "Este script requer privilégios de root."; exit 1; }

for pkg in curl jq rsync; do
    sys_programa_esta_instalado "$pkg" || instala_pacote_quieto "$pkg"
done
```
