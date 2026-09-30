# A1 – Plataforma de Streaming · MySQL no Docker + VS Code

Projeto organizado para rodar os scripts do item 9 da atividade A1 (Bancos e Armazéns de Dados – Fatec Cotia)
passo a passo, tirando o print de cada etapa.

## Estrutura

```
a1_streaming_db/
├── docker-compose.yml          # MySQL 8.0 em container (porta 3307 no seu PC)
├── .vscode/
│   ├── extensions.json         # extensões recomendadas (o VS Code oferece instalar ao abrir a pasta)
│   ├── settings.json           # conexão do SQLTools já configurada
│   └── tasks.json              # tarefas "A1: ..." para subir o banco e rodar cada script
├── sql/                        # um arquivo por item do trabalho, na ordem de execução
│   ├── 00_criar_banco.sql              → 9.1
│   ├── 01_criar_tabelas.sql            → 9.2
│   ├── 02_inserir_registros.sql        → 9.3
│   ├── 03_alter_add_coluna.sql         → 9.4
│   ├── 04_alter_rename_coluna.sql      → 9.5
│   ├── 05_alter_drop_coluna.sql        → 9.6
│   ├── 06_update.sql                   → 9.7
│   ├── 07_delete.sql                   → 9.8
│   └── 08_consultas_bonus.sql          → opcional (JOINs para a apresentação)
├── entrega/
│   └── A1_streaming_db_scripts.sql     # os mesmos comandos em um único arquivo, para entregar no Teams
├── backend/  frontend/                 # webapp StreamFlix (FastAPI + MySQL) — ver README1.md
└── start.sh  stop.sh                   # sobe / para tudo com um comando
```

## Webapp StreamFlix (bônus)

Além dos scripts, o projeto traz um site que usa o banco de verdade: catálogo, histórico, usuários,
assinaturas e um explorador do banco com console SQL e checklist dos itens 9.1–9.8.

```bash
chmod +x start.sh stop.sh   # 1ª vez
./start.sh                  # MySQL + scripts (se o banco estiver vazio) + API + navegador
./stop.sh                   # para tudo
```

Detalhes em `README1.md`. O webapp **não altera a estrutura do banco** — só lê e grava dados.

## Pré-requisitos

- **Docker Desktop** instalado e aberto (o ícone da baleia precisa estar rodando).
- **VS Code** com as extensões recomendadas: ao abrir a pasta, aceite o aviso *"Este workspace tem recomendações de extensão"*.
  Se não aparecer, instale manualmente: `SQLTools`, `SQLTools MySQL/MariaDB Driver` e `Docker`.

## Passo a passo

### 1. Subir o MySQL
`Terminal → Run Task… → A1: subir o MySQL (docker compose up)` — ou, no terminal do VS Code:

```bash
docker compose up -d
docker compose ps        # espere a coluna STATUS mostrar "healthy" (na 1ª vez leva ~30 s, baixa a imagem)
```

Dados de acesso: host `localhost`, porta `3307`, usuário `root`, senha `fatec123`, banco `streaming_db`.

### 2. Rodar os scripts — escolha um dos dois jeitos

**Jeito A – SQLTools (resultado em grade, bom para print)**
1. Clique no ícone do SQLTools na barra lateral → conexão **A1 - streaming_db (Docker)** → *Connect*.
2. Abra `sql/00_criar_banco.sql`, selecione tudo (`Ctrl+A`) e execute com `Ctrl+E Ctrl+E`
   (ou clique em *Run on active connection* acima do comando).
3. Cada comando abre uma aba de resultado. Tire o print e siga para o próximo arquivo, na ordem 00 → 07.

**Jeito B – Tarefas do VS Code (saída em texto no terminal, estilo "cliente mysql")**
1. `Terminal → Run Task… → A1: 00 - 9.1 criar banco` … até `A1: 07 - 9.8 excluir dado`.
2. A saída mostra o comando executado e o resultado logo abaixo (`-vvv`), já em formato de tabela — é o print de "script + resultado" que a professora pede.
3. `A1: rodar TUDO na ordem (00 a 07)` executa a sequência inteira (útil para testar do zero).

> Precisa recomeçar? `A1: ZERAR tudo e subir de novo` apaga o volume e sobe um banco limpo. Depois rode a partir do `00`.

### 3. O que printar em cada item

| Item | Arquivo | Print |
|------|---------|-------|
| 9.1 | 00 | `SHOW DATABASES LIKE 'streaming_db'` |
| 9.2 | 01 | `SHOW TABLES` + `DESCRIBE assinatura` + `DESCRIBE historico_visualizacao` |
| 9.3 | 02 | a contagem por tabela (todas com 10) + `SELECT * FROM plano` |
| 9.4 | 03 | `DESCRIBE usuario` mostrando a coluna `telefone` |
| 9.5 | 04 | `DESCRIBE conteudo` mostrando `data_adicao_catalogo` |
| 9.6 | 05 | `DESCRIBE genero` sem `descricao` |
| 9.7 | 06 | os dois `SELECT` (antes 55,90 / depois 59,90) |
| 9.8 | 07 | os dois `SELECT` (antes com o id 5 / depois com 9 registros) |

## Problemas comuns

| Sintoma | Causa / solução |
|---------|-----------------|
| `docker: command not found` ou erro de pipe | Docker Desktop não está aberto. Abra e aguarde o ícone ficar verde. |
| `port is already allocated` | Outro serviço usa a 3307. Troque `"3307:3306"` no `docker-compose.yml` e a `port` em `.vscode/settings.json`. |
| SQLTools: `ECONNREFUSED` | Container ainda inicializando. Rode `docker compose ps` e espere `healthy`. |
| SQLTools: `ER_NOT_SUPPORTED_AUTH_MODE` | Não deve ocorrer (o compose já usa `mysql_native_password`). Se ocorrer, rode `A1: ZERAR tudo e subir de novo`. |
| `Unknown database 'streaming_db'` | Rode o `00_criar_banco.sql` primeiro. |
| Erro de FK ao inserir | Os arquivos foram rodados fora de ordem. Zere o banco e siga 00 → 07. |

## Segurança

A senha `fatec123` é apenas para este container local de estudo; ela aparece em `docker-compose.yml`,
`.vscode/settings.json` e `.vscode/tasks.json`. Se trocar, troque nos três lugares.
