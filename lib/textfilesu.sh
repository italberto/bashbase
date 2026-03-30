# shellcheck shell=bash
# textfilesu.sh - Funções para leitura, busca e modificação de arquivos de texto
#
# Fornece operações de contagem de linhas/palavras/bytes, busca por conteúdo,
# substituição de texto com backup automático e conversão de line endings.
#
# As funções de contagem imprimem o resultado no stdout como inteiro puro,
# sem unidade, para facilitar comparações aritméticas.
# As funções de substituição modificam o arquivo em disco (in-place).
# Todas as funções retornam 1 se o arquivo informado não existir.
#
# Quando DRYRUN="1", as funções de substituição e conversão simulam suas operações
# sem modificar nenhum arquivo. O backup automático de tf_substitui_tudo também
# é simulado (via backupu.sh que respeita DRYRUN).
#
# Dependências: alerta.sh, backupu.sh, dryrun.sh
#
# Funções disponíveis:
#   tf_conta_linhas               <arquivo>           - Número total de linhas
#   tf_conta_palavras             <arquivo>           - Número total de palavras
#   tf_conta_caracteres           <arquivo>           - Número de caracteres Unicode
#   tf_conta_bytes                <arquivo>           - Número de bytes (tamanho bruto)
#   tf_conta_linhas_nao_vazias    <arquivo>           - Linhas que têm ao menos um caractere não-espaço
#   tf_conta_linhas_unicas        <arquivo>           - Número de linhas distintas (sem duplicatas)
#   tf_conta_ocorrencias          <arquivo> <palavra> - Número de ocorrências de uma palavra/padrão
#   tf_arquivo_contem             <arquivo> <palavra> - Verdadeiro se o arquivo contiver a palavra
#   tf_substitui_tudo             <arquivo> <old> <new> - Substitui todas as ocorrências (com backup)
#   tf_substitui_primeira         <arquivo> <old> <new> - Substitui apenas a primeira ocorrência
#   tf_substitui_ultima           <arquivo> <old> <new> - Substitui apenas a última ocorrência
#   tf_e_fim_de_linha_unix        <arquivo>           - Verdadeiro se line ending for LF (Unix)
#   tf_e_fim_de_linha_windows     <arquivo>           - Verdadeiro se line ending for CRLF (Windows)
#   tf_converte_para_fim_de_linha_unix    <arquivo>   - Converte CRLF → LF
#   tf_converte_para_fim_de_linha_windows <arquivo>   - Converte LF → CRLF


[[ -n "${_TEXTFILESU_SH_LOADED:-}" ]] && return 0
readonly _TEXTFILESU_SH_LOADED=1

source "$(dirname "${BASH_SOURCE[0]}")/alerta.sh"
source "$(dirname "${BASH_SOURCE[0]}")/backupu.sh"
source "$(dirname "${BASH_SOURCE[0]}")/dryrun.sh"

function tf_conta_linhas() {
    # Retorna o número total de linhas do arquivo como inteiro.
    # Uma linha é delimitada por \n. Arquivos sem \n final têm sua última
    # linha contada normalmente pelo wc.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_linhas /var/log/syslog
    #              total=$(tf_conta_linhas "$arq")
    #              echo "$arq tem $total linhas"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        wc -l < "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo"
        return 1
    fi
}

function tf_conta_palavras() {
    # Retorna o número de palavras do arquivo como inteiro.
    # Uma "palavra" é qualquer sequência de caracteres não-espaço separada
    # por espaço, tab ou newline (definição de wc -w).
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_palavras relatorio.txt
    #              [ "$(tf_conta_palavras "$arq")" -gt 500 ] && alerta "Texto longo"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        wc -w < "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_conta_caracteres() {
    # Retorna o número de caracteres Unicode do arquivo (usa wc -m).
    # Diferente de tf_conta_bytes: caracteres multibyte (acentos, emojis, CJK)
    # contam como 1 caractere, mas ocupam mais de 1 byte.
    # Depende do locale do sistema estar configurado para UTF-8.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_caracteres artigo.txt
    #              chars=$(tf_conta_caracteres "$arq")
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        wc -m < "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_conta_bytes() {
    # Retorna o tamanho bruto do arquivo em bytes como inteiro.
    # Equivalente a tamanho_do_arquivo de filesu.sh, mas via wc.
    # Para arquivos com caracteres multibyte, difere de tf_conta_caracteres.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_bytes imagem.jpg
    #              [ "$(tf_conta_bytes "$arq")" -gt 1048576 ] && alerta "Arquivo maior que 1 MB"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        wc -c < "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_conta_linhas_nao_vazias() {
    # Retorna o número de linhas que contêm ao menos um caractere não-espaço.
    # Linhas compostas apenas por espaços e tabs são tratadas como vazias e
    # não entram na contagem.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_linhas_nao_vazias script.sh
    #              cod=$(tf_conta_linhas_nao_vazias "$arq")
    #              vaz=$(( $(tf_conta_linhas "$arq") - cod ))
    #              echo "$vaz linhas em branco no arquivo"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        grep -cve '^\s*$' "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_conta_linhas_unicas() {
    # Retorna o número de linhas distintas no arquivo como inteiro.
    # Linhas duplicadas são contadas apenas uma vez, independente de quantas
    # vezes apareçam. A comparação é feita após ordenação interna (sort -u).
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_linhas_unicas ips.txt
    #              unicos=$(tf_conta_linhas_unicas "$log")
    #              total=$(tf_conta_linhas "$log")
    #              echo "$unicos entradas distintas de $total total"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        sort -u "$arquivo" | wc -l
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_conta_ocorrencias() {
    # Conta quantas vezes uma palavra ou padrão grep aparece no arquivo.
    # O padrão é tratado como expressão regular básica (BRE), igual ao grep.
    # A contagem soma todas as ocorrências em todas as linhas (não apenas
    # linhas que contêm o padrão, mas cada ocorrência individualmente).
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_conta_ocorrencias /var/log/auth.log "Failed password"
    #              tf_conta_ocorrencias config.yaml "host:"
    local arquivo="$1"
    local palavra="$2"
    if [[ -f "$arquivo" ]]; then
        grep -o "$palavra" "$arquivo" | wc -l
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_arquivo_contem() {
    # Retorna 0 se o arquivo contiver a palavra ou padrão informado, 1 caso contrário.
    # O padrão é tratado como expressão regular básica (BRE), igual ao grep.
    # A busca percorre todas as linhas; para no primeiro match encontrado.
    # Retorna 1 também se o arquivo não existir.
    # Modo de uso: tf_arquivo_contem /etc/fstab "UUID" && echo "fstab usa UUID"
    #              tf_arquivo_contem "$config" "^DEBUG=1" || alerta "Debug não ativado"
    local arquivo="$1"
    local palavra="$2"
    if [[ -f "$arquivo" ]]; then
        if grep -q "$palavra" "$arquivo"; then
            return 0
        else
            return 1
        fi
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_substitui_tudo() {
    # Substitui todas as ocorrências de palavra_antiga por palavra_nova no arquivo,
    # modificando-o em disco (operação in-place).
    #
    # BACKUP AUTOMÁTICO: antes de qualquer modificação, cria uma cópia do arquivo
    # original com timestamp (via backupu.sh). Se o backup falhar, a substituição
    # é cancelada e o arquivo original permanece intacto.
    #
    # Os padrões são tratados como literais: caracteres como /, &, \ são
    # escapados automaticamente para evitar quebra do comando sed.
    #
    # Retorna 1 se o arquivo não existir ou se o backup falhar.
    #
    # Modo de uso: substitui_tudo /etc/app/config.env "host_antigo" "host_novo"
    #              substitui_tudo nginx.conf "http://api.local" "https://api.prod.com"
    local arquivo="$1"
    local palavra_antiga="$2"
    local palavra_nova="$3"

    if [[ ! -f "$arquivo" ]]; then
        erro "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi

    local backup
    backup=$(backup_arquivo "$arquivo") || {
        erro "Não foi possível criar backup de '$arquivo'. Substituição cancelada." >&2
        return 1
    }

    if [[ "${DRYRUN:-}" = "1" ]]; then
        info "[DRY-RUN] Backup seria criado: $backup"
    else
        info "Backup criado: $backup"
    fi
    local old_esc="${palavra_antiga//\\/\\\\}"
    old_esc="${old_esc//|/\\|}"
    local new_esc="${palavra_nova//\\/\\\\}"
    new_esc="${new_esc//&/\\&}"
    new_esc="${new_esc//|/\\|}"
    dryrun_exec "tf_substitui_tudo: sed -i 's|$old_esc|$new_esc|g' '$arquivo'" \
        sed -i "s|$old_esc|$new_esc|g" "$arquivo"
}

function tf_substitui_primeira() {
    # Substitui apenas a primeira ocorrência de palavra_antiga por palavra_nova
    # no arquivo, modificando-o em disco (operação in-place).
    # Útil quando o padrão pode aparecer múltiplas vezes mas apenas a primeira
    # instância deve ser alterada (ex: primeira declaração de uma variável).
    # Os padrões são escapados automaticamente para uso seguro com sed.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_substitui_primeira /etc/hosts "127.0.0.1 localhost" "127.0.0.1 meuhost"
    local arquivo="$1"
    local palavra_antiga="$2"
    local palavra_nova="$3"
    if [[ -f "$arquivo" ]]; then
        local old_esc="${palavra_antiga//\\/\\\\}"
        old_esc="${old_esc//|/\\|}"
        local new_esc="${palavra_nova//\\/\\\\}"
        new_esc="${new_esc//&/\\&}"
        new_esc="${new_esc//|/\\|}"
        dryrun_exec "tf_substitui_primeira: sed primeira ocorrência '$palavra_antiga' em '$arquivo'" \
            sed -i "0,|$old_esc|s|$old_esc|$new_esc|" "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_substitui_ultima() {
    # Substitui apenas a última ocorrência de palavra_antiga por palavra_nova
    # no arquivo, modificando-o em disco (operação in-place).
    # Útil quando o padrão aparece múltiplas vezes e apenas a última instância
    # deve ser alterada (ex: última entrada de um log, último bloco de config).
    # Os padrões são escapados automaticamente para uso seguro com sed.
    # ATENÇÃO: a implementação lê o arquivo inteiro em memória para localizar
    # a última ocorrência — evite em arquivos muito grandes (> algumas dezenas de MB).
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_substitui_ultima deploy.log "status: pending" "status: done"
    local arquivo="$1"
    local palavra_antiga="$2"
    local palavra_nova="$3"
    if [[ -f "$arquivo" ]]; then
        local old_esc="${palavra_antiga//\\/\\\\}"
        old_esc="${old_esc//|/\\|}"
        local new_esc="${palavra_nova//\\/\\\\}"
        new_esc="${new_esc//&/\\&}"
        new_esc="${new_esc//|/\\|}"
        dryrun_exec "tf_substitui_ultima: sed última ocorrência '$palavra_antiga' em '$arquivo'" \
            sed -i ":a;N;\$!ba;s|\(.*\)$old_esc|\1$new_esc|" "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_e_fim_de_linha_unix() {
    # Retorna 0 se o arquivo usar line endings Unix (LF, \n).
    # Retorna 1 se usar line endings Windows (CRLF, \r\n) ou se não existir.
    # Use para verificar antes de processar arquivos que podem vir de ambientes
    # Windows, onde ferramentas como awk e grep podem se comportar de forma inesperada.
    # Modo de uso: tf_e_fim_de_linha_unix script.sh || tf_converte_para_fim_de_linha_unix script.sh
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        if file "$arquivo" | grep -q "CRLF"; then
            return 1
        else
            return 0
        fi
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_e_fim_de_linha_windows() {
    # Retorna 0 se o arquivo usar line endings Windows (CRLF, \r\n).
    # Retorna 1 se usar line endings Unix (LF) ou se não existir.
    # Modo de uso: tf_e_fim_de_linha_windows "$arq" && tf_converte_para_fim_de_linha_unix "$arq"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        if file "$arquivo" | grep -q "CRLF"; then
            return 0
        else
            return 1
        fi
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_converte_para_fim_de_linha_unix() {
    # Remove os caracteres \r de cada linha do arquivo, convertendo CRLF → LF.
    # Modifica o arquivo em disco (in-place). Arquivos que já usam LF não são afetados.
    # Útil para normalizar arquivos vindos de ambientes Windows antes de processá-los
    # com ferramentas Unix (awk, grep, bash, etc.) que podem não tratar \r corretamente.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_converte_para_fim_de_linha_unix config.env
    #              tf_e_fim_de_linha_windows "$arq" && tf_converte_para_fim_de_linha_unix "$arq"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        dryrun_exec "tf_converte_para_fim_de_linha_unix: CRLF→LF em '$arquivo'" \
            sed -i 's/\r$//' "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}

function tf_converte_para_fim_de_linha_windows() {
    # Adiciona \r ao final de cada linha do arquivo, convertendo LF → CRLF.
    # Modifica o arquivo em disco (in-place).
    # Útil para gerar arquivos que precisam ser lidos em editores ou sistemas
    # Windows que esperam CRLF (ex: Notepad, algumas ferramentas legadas).
    # ATENÇÃO: aplicar em um arquivo que já tem CRLF duplica o \r (\r\r\n).
    # Verifique com tf_e_fim_de_linha_unix antes de converter.
    # Retorna 1 se o arquivo não existir.
    # Modo de uso: tf_e_fim_de_linha_unix "$arq" && tf_converte_para_fim_de_linha_windows "$arq"
    local arquivo="$1"
    if [[ -f "$arquivo" ]]; then
        dryrun_exec "tf_converte_para_fim_de_linha_windows: LF→CRLF em '$arquivo'" \
            sed -i 's/$/\r/' "$arquivo"
    else
        alerta "Arquivo não encontrado: $arquivo" >&2
        return 1
    fi
}
