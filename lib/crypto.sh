# shellcheck shell=bash
# Funções relacionadas à criptografia usando OpenSSL.

source "$(dirname "${BASH_SOURCE[0]}")/systemu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/alerta.sh"

[[ -n "${_CRYPTO_SH_LOADED:-}" ]] && return 0
readonly _CRYPTO_SH_LOADED=1

function crypt_gerar_chave() {
    # Gera uma chave criptográfica usando OpenSSL.
    if ! sys_programa_esta_instalado "openssl"; then
        erro "OpenSSL não está instalado. Instale-o para usar esta função."
        return 1
    fi
    openssl rand -hex 32
}

function crypt_hash_string() {
    # Retorna o hash SHA256 de uma string fornecida.
    if ! sys_programa_esta_instalado "openssl"; then
        erro "OpenSSL não está instalado. Instale-o para usar esta função."
        return 1
    fi
    echo -n "$1" | openssl dgst -sha256
}

function crypt_hash_md5() {
    # Retorna o hash MD5 de uma string fornecida.
    if ! sys_programa_esta_instalado "openssl"; then
        erro "OpenSSL não está instalado. Instale-o para usar esta função."
        return 1
    fi  
    echo -n "$1" | openssl dgst -md5
}

function crypt_hash_sha1() {
    # Retorna o hash SHA1 de uma string fornecida.
    if ! sys_programa_esta_instalado "openssl"; then
        erro "OpenSSL não está instalado. Instale-o para usar esta função."
        return 1
    fi
    echo -n "$1" | openssl dgst -sha1
}

function crypt_hash_de_arquivo() {
    # Retorna o hash SHA256 de um arquivo especificado.
    if ! sys_programa_esta_instalado "openssl"; then
        erro "OpenSSL não está instalado. Instale-o para usar esta função."
        return 1
    fi
    openssl dgst -sha256 "$1"
}

function crypt_valida_hash_de_arquivo() {
    # Compara o hash SHA256 de um arquivo com um hash esperado.
    if ! sys_programa_esta_instalado "openssl"; then
        erro "OpenSSL não está instalado. Instale-o para usar esta função."
        return 1
    fi
    local file_hash
    file_hash=$(openssl dgst -sha256 "$1" | awk '{print $NF}')
    if [ "$file_hash" == "$2" ]; then
        return 0
    else
        return 1
    fi
}