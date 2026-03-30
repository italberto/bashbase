# crypto — Hashes e chaves criptográficas via OpenSSL

**Arquivo:** `crypto.sh`
**Dependências:** `systemu.sh`, `alerta.sh`

Fornece funções para geração de chaves aleatórias e cálculo de hashes criptográficos usando o OpenSSL. Todas as funções verificam se o OpenSSL está instalado e retornam 1 com mensagem de erro se não estiver.

## Referência rápida

| Função | Descrição |
|--------|-----------|
| `crypt_gerar_chave` | Gera uma chave hexadecimal aleatória de 256 bits |
| `crypt_hash_string` | Hash SHA-256 de uma string |
| `crypt_hash_md5` | Hash MD5 de uma string |
| `crypt_hash_sha1` | Hash SHA-1 de uma string |
| `crypt_hash_de_arquivo` | Hash SHA-256 de um arquivo |
| `crypt_valida_hash_de_arquivo` | Compara hash SHA-256 de um arquivo com valor esperado |

## Funções

### `crypt_gerar_chave`

Gera 32 bytes aleatórios via `/dev/urandom` e os retorna em hexadecimal (64 caracteres).

```bash
chave=$(crypt_gerar_chave)
echo "Chave gerada: $chave"
# → a3f2e891c4d5b6a7...
```

---

### `crypt_hash_string <texto>`

Retorna o hash SHA-256 da string fornecida. A saída inclui o prefixo `(stdin)= ` do OpenSSL.

```bash
crypt_hash_string "minha senha"
# → (stdin)= 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd...
```

---

### `crypt_hash_md5 <texto>`

Retorna o hash MD5 da string fornecida.

```bash
crypt_hash_md5 "texto de teste"
# → (stdin)= 79054025255fb1a26e4bc422aef54eb4
```

---

### `crypt_hash_sha1 <texto>`

Retorna o hash SHA-1 da string fornecida.

```bash
crypt_hash_sha1 "texto de teste"
```

---

### `crypt_hash_de_arquivo <arquivo>`

Retorna o hash SHA-256 de um arquivo. A saída inclui o caminho do arquivo.

```bash
crypt_hash_de_arquivo /etc/passwd
# → SHA256(/etc/passwd)= 4a9...
```

---

### `crypt_valida_hash_de_arquivo <arquivo> <hash_esperado>`

Compara o hash SHA-256 do arquivo com o valor esperado. Retorna 0 se idênticos, 1 caso contrário.

```bash
hash_esperado="abc123..."

if crypt_valida_hash_de_arquivo /tmp/download.tar.gz "$hash_esperado"; then
    sucesso "Integridade verificada"
else
    erro "Hash não confere — arquivo corrompido ou adulterado"
    exit 1
fi
```
