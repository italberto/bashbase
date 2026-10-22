# Changelog

Todas as mudanças notáveis neste projeto serão documentadas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adota [Semantic Versioning](https://semver.org/lang/pt-BR/).

---

## [Não lançado]

### Corrigido
- `configu.sh`: `config_ler`, `config_existe` e `config_escrever` não encontravam chaves existentes (a troca para `grep -F` tornara o `^` literal, quebrando a âncora de início de linha)
- `configu.sh`: `config_escrever` duplicava chaves e `config_remover` não removia nada, devido a escape de `sed` malformado (`[.` interpretado como símbolo de colação POSIX)
- Correspondência de chave agora é feita com `awk index()` — literal e ancorada, sem interpretar a chave como regex

### Adicionado
- Testes unitários em `tests/unit/teste_configu.sh` cobrindo leitura, escrita in-place, remoção e chaves/valores com metacaracteres

### Removido
- `projeto_completo.txt` — dump concatenado do projeto que não deveria estar versionado

## [1.2.0] - 2026-03-30

### Adicionado
- Módulo `tempu.sh`: criação de arquivos e diretórios temporários com cleanup automático integrado à pilha de sinais (`sinais.sh`) — funções `tmp_criar_arquivo`, `tmp_criar_diretorio`, `tmp_registrar`, `tmp_limpar_tudo`
- Documentação em `docs/tempu.md`
- Exemplo em `examples/exemplo_tempu.sh`

## [1.1.0] - 2026-03-30

### Adicionado
- Módulo `redes.sh`: primitivos de diagnóstico de rede — porta, interface, gateway, Wi-Fi, Ethernet, DNS e internet
- Camada de serviços `lib/servicos/` para módulos de alto nível que dependem de sistemas externos
- Módulo `servicos/conectividade.sh`: verificação de disponibilidade de serviços por porta (SSH, HTTP, HTTPS, FTP, SMTP, etc.)
- Módulo `servicos/postgres.sh`: verificação, queries e replicação em instâncias PostgreSQL (`pg_esta_rodando`, `pg_banco_existe`, `pg_executar_sql`, `pg_contar_conexoes`, `pg_versao`, `pg_checar_replicacao`)
- Módulo `servicos/jboss.sh`: deployments, saúde e management de instâncias JBoss/WildFly (`jboss_esta_rodando`, `jboss_management_disponivel`, `jboss_deployment_ativo`, `jboss_listar_deployments`, `jboss_checar_saude`, `jboss_versao`)
- Documentação em `docs/redes.md`, `docs/servicos/conectividade.md`, `docs/servicos/postgres.md`, `docs/servicos/jboss.md`
- Exemplos em `examples/servicos/exemplo_postgres.sh` e `examples/servicos/exemplo_jboss.sh`
- Testes unitários em `tests/unit/teste_servicos_redes.sh`

### Alterado
- `conectividade.sh` substituído por dois módulos: primitivos de rede movidos para `redes.sh`; wrappers de serviço movidos para `servicos/conectividade.sh`
- `examples/exemplo_conectividade.sh` atualizado para usar os novos caminhos e nomes de função
- README atualizado: índice dividido em Primitivos/Serviços, grafo de dependências revisado e seção de arquitetura em duas camadas

### Removido
- `lib/conectividade.sh` — substituído por `lib/redes.sh` e `lib/servicos/conectividade.sh`
- `docs/conectividade.md` — substituído por `docs/redes.md` e `docs/servicos/conectividade.md`

## [1.0.0] - 2026-03-29

### Adicionado
- Módulo `alerta.sh`: mensagens coloridas e categorizadas no terminal
- Módulo `argsu.sh`: parsing declarativo de argumentos de linha de comando
- Módulo `backupu.sh`: backup de arquivos e diretórios com timestamp
- Módulo `boolean.sh`: padrões de booleanos para uso em scripts
- Módulo `configu.sh`: leitura e escrita de arquivos `.env` / `CHAVE=valor`
- Módulo `conectividade.sh`: verificação de rede, DNS, portas e serviços
- Módulo `cores.sh`: colorização de texto com códigos ANSI
- Módulo `crypto.sh`: hashes e chaves criptográficas via OpenSSL
- Módulo `datau.sh`: timestamps, formatação de datas e cálculo de durações
- Módulo `diru.sh`: inspeção e metadados de diretórios
- Módulo `distu.sh`: detecção de distribuição Linux e informações do SO
- Módulo `downu.sh`: download de arquivos via wget, curl ou TCP nativo
- Módulo `dryrun.sh`: suporte a modo de simulação sem efeitos colaterais
- Módulo `filesu.sh`: verificação, metadados e comparação de arquivos
- Módulo `inputs.sh`: coleta interativa de dados do usuário
- Módulo `logu.sh`: logging estruturado com níveis e rotação de arquivo
- Módulo `mockfiles.sh`: criação de arquivos fictícios para testes
- Módulo `pkgu.sh`: abstração para gerenciadores de pacotes (apt/dnf/pacman…)
- Módulo `procesu.sh`: gerenciamento de processos e lock de execução exclusiva
- Módulo `resourcesu.sh`: monitoramento de CPU, memória e disco
- Módulo `retryu.sh`: retry automático com delay fixo ou backoff exponencial
- Módulo `runu.sh`: execução de comandos com spinner e timeout
- Módulo `servicou.sh`: gerenciamento de serviços systemd
- Módulo `sinais.sh`: stack de cleanup garantido via traps de sinal
- Módulo `spinner.sh`: animações de progresso no terminal
- Módulo `systemu.sh`: utilitários gerais de sistema (root, PATH, exit codes)
- Módulo `textfilesu.sh`: contagem, busca e substituição em arquivos de texto
- Módulo `utils.sh`: manipulação de strings e extração de campos
- Módulo `validau.sh`: validação de IP, e-mail, URL, porta e variáveis
- Módulo `version.sh`: metadados e informações de versão da biblioteca
