# resourcesu — Monitoramento de CPU, memória e disco

**Arquivo:** `resourcesu.sh`
**Dependências:** nenhuma

Fornece funções para consultar informações sobre CPU, memória RAM e disco, além de listar interfaces de rede. Depende de `/proc` para leituras de memória (Linux).

Funções numéricas retornam **inteiros puros sem unidade**, deixando a formatação a cargo do chamador:
- Funções `memoria_*` → valor em **kB**
- Funções `uso_*` → percentual inteiro (**0–100**)

## Referência rápida

| Função | Tipo de retorno | Descrição |
|--------|----------------|-----------|
| `modelo_de_cpu` | string | Modelo do processador |
| `memoria_total` | inteiro (kB) | Memória RAM total |
| `memoria_disponivel` | inteiro (kB) | Memória RAM disponível |
| `memoria_usada` | inteiro (kB) | Memória RAM em uso |
| `uso_do_disco` | inteiro (0-100) | Percentual de uso do disco |
| `uso_da_cpu` | inteiro (0-100) | Percentual de uso da CPU |
| `uso_da_memoria` | inteiro (0-100) | Percentual de uso da memória |
| `lista_interfaces_de_rede` | linhas de texto | Interfaces de rede disponíveis |

## Funções

### `modelo_de_cpu`

Retorna o modelo do processador lendo `/proc/cpuinfo`. Retorna `"Desconhecido"` em sistemas sem `/proc/cpuinfo` (ex: macOS).

```bash
echo "CPU: $(modelo_de_cpu)"
# → CPU: Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz
```

---

### `memoria_total`

Retorna a memória RAM total em kB (lê `MemTotal` de `/proc/meminfo`).

```bash
total=$(memoria_total)
echo "RAM total: $((total / 1024)) MB"
echo "RAM total: $((total / 1024 / 1024)) GB"
```

---

### `memoria_disponivel`

Retorna a memória RAM disponível para novos processos em kB (lê `MemAvailable`). Mais precisa que `MemFree` pois inclui cache liberável.

```bash
disp=$(memoria_disponivel)
echo "Disponível: $((disp / 1024)) MB"
```

---

### `memoria_usada`

Retorna a memória RAM em uso em kB, calculada como `MemTotal - MemAvailable`.

```bash
usada=$(memoria_usada)
echo "Em uso: $((usada / 1024)) MB"
```

---

### `uso_do_disco [caminho]`

Retorna o percentual de uso do disco como inteiro (0-100). Se um caminho for fornecido, usa o sistema de arquivos daquele caminho. Caso contrário, usa `/`.

```bash
uso=$(uso_do_disco)
uso=$(uso_do_disco /var/log)

[ "$uso" -gt 90 ] && erro "Disco quase cheio: ${uso}%"
```

---

### `uso_da_cpu`

Retorna o percentual de uso da CPU como inteiro (0-100), calculado como `100 - %idle` via `top`.

```bash
cpu=$(uso_da_cpu)
[ "$cpu" -gt 80 ] && alerta "CPU acima de 80%: ${cpu}%"
```

---

### `uso_da_memoria`

Retorna o percentual de uso da memória RAM como inteiro (0-100), calculado via `free -m`.

```bash
mem=$(uso_da_memoria)
[ "$mem" -gt 90 ] && erro "Memória crítica: ${mem}%"
```

---

### `lista_interfaces_de_rede`

Lista os nomes de todas as interfaces de rede disponíveis, uma por linha.

```bash
lista_interfaces_de_rede
# lo
# eth0
# wlan0
```

## Exemplo: alerta de recursos

```bash
source "$BASHBASE/resourcesu.sh"
source "$BASHBASE/alerta.sh"

disco=$(uso_do_disco)
mem=$(uso_da_memoria)
cpu=$(uso_da_cpu)

[ "$disco" -gt 85 ] && alerta "Disco: ${disco}% usado"
[ "$mem"   -gt 90 ] && erro   "Memória crítica: ${mem}%"
[ "$cpu"   -gt 95 ] && alerta "CPU: ${cpu}%"

info "CPU: $(modelo_de_cpu)"
info "RAM total: $(( $(memoria_total) / 1024 )) MB"
```
