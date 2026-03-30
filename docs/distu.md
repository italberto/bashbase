# distu — Detecção de distribuição Linux e informações do SO

**Arquivo:** `distu.sh`
**Dependências:** nenhuma

Fornece funções para detectar a distribuição Linux em uso e consultar informações básicas do sistema operacional. Cada função de detecção verifica arquivos característicos em `/etc/`.

## Referência rápida

### Detecção de distribuição

| Função | Distribuição | Arquivo verificado |
|--------|-------------|-------------------|
| `dist_e_debian` | Debian | `/etc/debian_version` |
| `dist_e_ubuntu` | Ubuntu | `/etc/lsb-release` (contém "Ubuntu") |
| `dist_e_fedora` | Fedora | `/etc/fedora-release` |
| `dist_e_arch` | Arch Linux | `/etc/arch-release` |
| `dist_e_redhat` | Red Hat Enterprise Linux | `/etc/redhat-release` |
| `dist_e_suse` | SuSE Linux | `/etc/SuSE-release` |
| `dist_e_gentoo` | Gentoo Linux | `/etc/gentoo-release` |
| `dist_e_alpine` | Alpine Linux | `/etc/alpine-release` |
| `dist_e_opensuse` | openSUSE | `/etc/os-release` (contém "openSUSE") |
| `dist_e_openbsd` | OpenBSD | `/etc/os-release` (contém "OpenBSD") |
| `dist_e_freebsd` | FreeBSD | `/etc/os-release` (contém "FreeBSD") |
| `dist_e_osx` | macOS | `/System/Library/CoreServices/SystemVersion.plist` |

### Informações do sistema

| Função | Descrição | Fonte |
|--------|-----------|-------|
| `dist_nome_do_so` | Nome do SO (ex: "Fedora Linux") | `/etc/os-release` (`NAME`) |
| `dist_versao_do_so` | Versão do SO (ex: "40") | `/etc/os-release` (`VERSION_ID`) |
| `dist_versao_do_kernel` | Versão do kernel (ex: "6.17.1") | `uname -r` |
| `dist_arquitetura` | Arquitetura do processador | `uname -m` |
| `dist_nome_do_host` | Nome do host da máquina | `uname -n` |
| `dist_tempo_ligado` | Tempo de atividade (uptime) | `uptime -p` ⚠️ |

## Funções de detecção

Todas retornam **0** se a distribuição for identificada e **1** caso contrário.

```bash
dist_e_debian  && echo "É Debian"
dist_e_ubuntu  && echo "É Ubuntu"
dist_e_fedora  && echo "É Fedora"
dist_e_arch    && echo "É Arch Linux"
dist_e_redhat  && echo "É Red Hat"
dist_e_alpine  && echo "É Alpine"
dist_e_osx     && echo "É macOS"
```

### Uso em scripts multi-distro

```bash
source "$BASHBASE/distu.sh"

if dist_e_debian || dist_e_ubuntu; then
    apt install -y curl
elif dist_e_fedora; then
    dnf install -y curl
elif dist_e_arch; then
    pacman -S --noconfirm curl
else
    erro "Distribuição não suportada"
    exit 1
fi
```

## Funções de informação

### `dist_nome_do_so`

```bash
echo "Sistema: $(dist_nome_do_so)"
# → Sistema: Fedora Linux
```

### `dist_versao_do_so`

```bash
echo "Versão: $(dist_versao_do_so)"
# → Versão: 40
```

### `dist_versao_do_kernel`

```bash
echo "Kernel: $(dist_versao_do_kernel)"
# → Kernel: 6.17.1-300.fc43.x86_64
```

### `dist_arquitetura`

```bash
echo "Arquitetura: $(dist_arquitetura)"
# → Arquitetura: x86_64
```

### `dist_nome_do_host`

```bash
echo "Host: $(dist_nome_do_host)"
# → Host: meu-computer
```

### `dist_tempo_ligado`

```bash
echo "Uptime: $(dist_tempo_ligado)"
# → Uptime: up 2 weeks, 3 days, 4 hours, 5 minutes
```

## Observação: pkgu.sh usa aliases antigos

O módulo `pkgu.sh` usa os nomes `isdebian`, `isubuntu`, `isfedora`, `isarch`, `isredhat`, `issuse`, `isgentoo`, `isalpine` como aliases das funções `dist_e_*`. Esses aliases podem precisar de atualização se os nomes forem alterados.
