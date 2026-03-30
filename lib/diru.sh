# shellcheck shell=bash
# diru.sh - Funções para inspeção e metadados de diretórios
#
# Fornece operações de contagem, listagem e consulta de metadados sobre
# diretórios e seu conteúdo. Todas as funções operam recursivamente
# (incluindo subdiretórios) salvo indicação em contrário.
#
# Todas as funções retornam 1 se o diretório informado não existir.
# Erros de permissão em subdiretórios são suprimidos silenciosamente.
#
# Dependências: nenhuma
#
# Funções disponíveis:
#   dir_tamanho_do_diretorio          <dir>  - Tamanho total em formato legível (ex: 1.4G, 234M)
#   dir_contar_arquivos               <dir>  - Número de arquivos regulares (recursivo)
#   dir_contar_diretorios             <dir>  - Número de diretórios (recursivo, inclui o próprio dir)
#   dir_contar_links_simbolicos       <dir>  - Número de links simbólicos (recursivo)
#   dir_contar_tudo                   <dir>  - Total de todos os itens (recursivo, inclui o próprio dir)
#   dir_listar_arquivos               <dir>  - Caminhos completos de todos os arquivos regulares
#   dir_listar_diretorios             <dir>  - Caminhos completos de todos os diretórios
#   dir_listar_links_simbolicos       <dir>  - Caminhos completos de todos os links simbólicos
#   dir_listar_tudo                   <dir>  - Caminhos completos de todos os itens
#   dir_permissoes_do_diretorio       <dir>  - Permissões no formato rwxr-xr-x
#   dir_dono_do_diretorio             <dir>  - Nome do usuário proprietário
#   dir_grupo_do_diretorio            <dir>  - Nome do grupo proprietário
#   dir_get_data_hora_ultima_modificacao <dir> - Data e hora da última modificação


[[ -n "${_DIRU_SH_LOADED:-}" ]] && return 0
readonly _DIRU_SH_LOADED=1

function dir_tamanho_do_diretorio() {
    # Retorna o tamanho total do diretório e de todo o seu conteúdo em formato
    # legível por humanos (ex: 4.0K, 234M, 1.4G). Usa du -sh internamente.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_tamanho_do_diretorio /var/log
    #              echo "Logs ocupam: $(dir_tamanho_do_diretorio /var/log)"
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        du -sh "$diretorio" 2>/dev/null | cut -f1
    else
        return 1
    fi
}

function dir_contar_arquivos() {
    # Conta o número de arquivos regulares dentro do diretório, incluindo
    # subdirectórios em qualquer profundidade. Links simbólicos e diretórios
    # não são contados — apenas arquivos do tipo regular (tipo f).
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_contar_arquivos /etc
    #              if [ "$(dir_contar_arquivos /tmp)" -gt 100 ]; then echo "muitos arquivos"; fi
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" -type f 2>/dev/null | wc -l
    else
        return 1
    fi
}

function dir_contar_diretorios() {
    # Conta o número de diretórios dentro do diretório informado, incluindo
    # subdirectórios em qualquer profundidade.
    # ATENÇÃO: o próprio diretório raiz é incluído na contagem. Um diretório
    # vazio retorna 1 (ele mesmo), não 0.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_contar_diretorios /etc
    #              subdirs=$(( $(dir_contar_diretorios /etc) - 1 ))  # descontar o próprio dir
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" -type d 2>/dev/null | wc -l
    else
        return 1
    fi
}

function dir_contar_links_simbolicos() {
    # Conta o número de links simbólicos dentro do diretório, incluindo
    # subdirectórios em qualquer profundidade.
    # Links quebrados (que apontam para alvos inexistentes) também são contados.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_contar_links_simbolicos /usr/bin
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" -type l 2>/dev/null | wc -l
    else
        return 1
    fi
}

function dir_contar_tudo() {
    # Conta o número total de itens dentro do diretório: arquivos regulares,
    # subdirectórios e links simbólicos, em qualquer profundidade.
    # ATENÇÃO: o próprio diretório raiz é incluído na contagem.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_contar_tudo /home/usuario
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" 2>/dev/null | wc -l
    else
        return 1
    fi
}

function dir_listar_arquivos() {
    # Lista os caminhos completos de todos os arquivos regulares dentro do
    # diretório, incluindo subdirectórios em qualquer profundidade.
    # Cada caminho é impresso em uma linha separada. Links simbólicos e
    # diretórios não são incluídos.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_listar_arquivos /etc/nginx
    #              dir_listar_arquivos /var/log | grep "\.log$"
    #              dir_listar_arquivos /tmp | xargs rm -f
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" -type f 2>/dev/null
    else
        return 1
    fi
}

function dir_listar_diretorios() {
    # Lista os caminhos completos de todos os diretórios dentro do diretório
    # informado, incluindo subdirectórios em qualquer profundidade.
    # ATENÇÃO: o próprio diretório raiz é incluído na listagem como primeiro item.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_listar_diretorios /etc
    #              dir_listar_diretorios /var | grep "cache"
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" -type d 2>/dev/null
    else
        return 1
    fi
}

function dir_listar_links_simbolicos() {
    # Lista os caminhos completos de todos os links simbólicos dentro do
    # diretório, incluindo subdirectórios em qualquer profundidade.
    # Links quebrados (alvos inexistentes) também são listados.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_listar_links_simbolicos /usr/bin
    #              dir_listar_links_simbolicos /etc | xargs ls -la
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" -type l 2>/dev/null
    else
        return 1
    fi
}

function dir_listar_tudo() {
    # Lista os caminhos completos de todos os itens dentro do diretório:
    # arquivos regulares, subdirectórios e links simbólicos, em qualquer profundidade.
    # ATENÇÃO: o próprio diretório raiz é incluído como primeiro item da listagem.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_listar_tudo /etc/nginx
    #              dir_listar_tudo /var/log | wc -l
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        find "$diretorio" 2>/dev/null
    else
        return 1
    fi
}

function dir_permissoes_do_diretorio() {
    # Retorna as permissões do diretório no formato simbólico rwxr-xr-x
    # (10 caracteres: tipo + dono + grupo + outros).
    # Equivalente à primeira coluna do ls -l.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_permissoes_do_diretorio /etc/ssh
    #              if [[ "$(dir_permissoes_do_diretorio /var/secret)" == "drwx------" ]]; then
    #                  echo "acesso restrito ao dono"
    #              fi
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        stat -c "%A" "$diretorio" 2>/dev/null
    else
        return 1
    fi
}

function dir_dono_do_diretorio() {
    # Retorna o nome de usuário do proprietário do diretório.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_dono_do_diretorio /var/www/html
    #              if [[ "$(dir_dono_do_diretorio /app)" != "www-data" ]]; then
    #                  erro "Diretório com dono incorreto"
    #              fi
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        stat -c "%U" "$diretorio" 2>/dev/null
    else
        return 1
    fi
}

function dir_grupo_do_diretorio() {
    # Retorna o nome do grupo proprietário do diretório.
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_grupo_do_diretorio /var/www/html
    #              if [[ "$(dir_grupo_do_diretorio /dados)" != "deploy" ]]; then
    #                  alerta "Grupo do diretório não é 'deploy'"
    #              fi
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        stat -c "%G" "$diretorio" 2>/dev/null
    else
        return 1
    fi
}

function dir_get_data_hora_ultima_modificacao() {
    # Retorna a data e hora da última modificação do diretório no formato
    # "YYYY-MM-DD HH:MM:SS.NNNNNNNNN +ZZZZ" (saída bruta do stat).
    # A modificação do diretório ocorre quando arquivos são criados, renomeados
    # ou removidos diretamente nele (não em subdirectórios).
    # Retorna 1 se o diretório não existir.
    # Modo de uso: dir_get_data_hora_ultima_modificacao /var/spool/cron
    #              echo "Último acesso: $(dir_get_data_hora_ultima_modificacao /tmp)"
    local diretorio="$1"
    if [[ -d "$diretorio" ]]; then
        stat -c "%y" "$diretorio" 2>/dev/null
    else
        return 1
    fi
}
