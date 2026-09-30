# StreamFlix · webapp de demonstração do `streaming_db`

Interface web (FastAPI + SQLAlchemy + MySQL 8 no Docker) para **testar e apresentar** o banco da A1.
Toda tela executa SQL real nas 9 tabelas criadas pelos scripts de `sql/` — o webapp **não cria nem
altera a estrutura do banco**; ele só lê e grava dados.

> O banco em si (scripts, modelo, entrega) está documentado no `README.md`.

## Subir e parar com um comando

```bash
chmod +x start.sh stop.sh     # só na primeira vez

./start.sh                    # sobe tudo e abre http://127.0.0.1:8000
./stop.sh                     # para tudo (dados preservados)
```

O `start.sh` faz, nesta ordem:

1. confere se o **Docker** está rodando (no macOS tenta abrir o Docker Desktop sozinho);
2. `docker compose up -d` e espera o **MySQL** ficar saudável e aceitar conexão;
3. se o `streaming_db` estiver **vazio**, executa os scripts `sql/00` → `sql/07` na ordem (itens 9.1 a 9.8).
   Se as tabelas já existem, não mexe em nada;
4. cria o `.venv` e instala o `requirements.txt` (só quando o arquivo muda);
5. cria o `.env` se não existir;
6. encerra uma API anterior, sobe o **uvicorn** em segundo plano (`.streamflix/api.pid` e `.streamflix/api.log`);
7. espera a API responder e abre o navegador.

| Comando | O que faz |
|---|---|
| `./start.sh` | sobe tudo (cria o banco só se estiver vazio) |
| `./start.sh --reset` | recria o banco do zero rodando os 8 scripts de novo (apaga dados de teste) |
| `./start.sh --dev` | API em primeiro plano com auto-reload (`Ctrl+C` encerra só a API) |
| `./start.sh --no-browser` | não abre o navegador |
| `./start.sh --purge` | remove container + volume do MySQL antes de subir |
| `PORT=8080 ./start.sh` | usa outra porta |
| `./stop.sh` | para a API e o container (dados ficam no volume) |
| `./stop.sh --keep-db` | para só a API |
| `./stop.sh --down` | para a API e remove o container (volume preservado) |
| `./stop.sh --purge` | para tudo e apaga o volume — o próximo `start.sh` recria o banco |

No VS Code: `Terminal → Run Task… → StreamFlix: ▶ iniciar tudo` / `⏹ parar tudo`.

## O que tem no site

| Tela | O que mostra | SQL por trás |
|---|---|---|
| **Início** | KPIs animados, as 9 tabelas com contagens, gráficos (títulos por gênero, assinaturas por status, receita por plano, quem mais assistiu), "continuar assistindo", últimas visualizações | `COUNT`, `SUM`, `GROUP BY`, `LEFT JOIN` |
| **Catálogo** | pôsteres gerados por título, busca ao vivo, filtros por tipo/gênero/classificação, ordenação | `LIKE`, `EXISTS`, subconsultas, `GROUP_CONCAT` |
| **Título** | ficha do filme/série, temporadas e episódios, estatísticas, quem assistiu, registrar visualização | `JOIN episodio`, `INSERT` em `historico_visualizacao` |
| **Histórico** | a consulta bônus do item 08 (JOIN em 5 tabelas) com filtros, progresso, concluir/editar/excluir | `UPDATE`, `DELETE` (item 9.8) |
| **Usuários** | usuários com plano ativo e minutos assistidos; criar/editar/excluir; perfis por conta | `INSERT`/`UPDATE`/`DELETE`, FK `RESTRICT` × `CASCADE` |
| **Assinaturas** | assinaturas com troca de status (ativa/suspensa/cancelada); planos com **alterar preço** (item 9.7) e excluir (mostra o erro 1451) | ENUM, `CHECK`, FK |
| **Banco de dados** | esquema lido do `information_schema` (colunas, PK/UNIQUE/FK/CHECK, relacionamentos), dados brutos paginados, **console SQL somente leitura** com exemplos prontos, **checklist 9.1–9.8** verificado no banco real | `information_schema`, `DESCRIBE`, `EXPLAIN` |

Os erros do MySQL aparecem traduzidos na tela (ex.: *"Restrição de integridade referencial — erro 1451"*),
o que ajuda a demonstrar as chaves estrangeiras e as `CHECK`s na apresentação.

## API

Documentação interativa em **http://127.0.0.1:8000/docs** (Swagger). Principais rotas:

```
GET  /api/health                 GET  /api/dashboard              GET  /api/receita
GET  /api/conteudos?busca=&tipo=&genero=&classificacao=&ordenar=
GET  /api/conteudos/{id}         GET  /api/generos
GET  /api/usuarios               POST /api/usuarios               PUT/DELETE /api/usuarios/{id}
GET  /api/perfis                 POST /api/perfis                 PUT/DELETE /api/perfis/{id}
GET  /api/planos                 POST /api/planos                 PUT  /api/planos/{id}/preco     DELETE /api/planos/{id}
GET  /api/assinaturas            POST /api/assinaturas            PATCH/DELETE /api/assinaturas/{id}
GET  /api/historico              POST /api/historico              PATCH/DELETE /api/historico/{id}
GET  /api/schema                 GET  /api/tabelas/{nome}         POST /api/sql (somente leitura)
GET  /api/sql/exemplos           GET  /api/checklist
```

## Estrutura

```
backend/
├── main.py            app FastAPI, CORS, tratamento de erros, arquivos estáticos
├── database.py        engine/sessão, helpers de consulta, introspecção do schema
├── errors.py          códigos do MySQL → mensagens em português + status HTTP
└── routers/
    ├── api.py         agrega os módulos abaixo em /api
    ├── sistema.py     /health /dashboard /receita
    ├── catalogo.py    /conteudos /generos
    ├── usuarios.py    /usuarios /perfis
    ├── assinaturas.py /planos /assinaturas
    ├── historico.py   /historico
    └── banco.py       /schema /tabelas /sql /checklist
frontend/
├── index.html         casca da SPA (rotas por hash: #/catalogo, #/banco/sql …)
├── style.css          design system (tema escuro)
└── app.js             telas, modais, gráficos, chamadas à API — sem framework, sem build
start.sh · stop.sh     automação completa
```

## Rodar na mão (sem os scripts)

```bash
docker compose up -d
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
echo 'DATABASE_URL=mysql+pymysql://root:fatec123@127.0.0.1:3307/streaming_db' > .env
uvicorn backend.main:app --reload
```

## Problemas comuns

| Sintoma | Solução |
|---|---|
| Faixa amarela *"Faltam tabelas"* no topo do site | `./start.sh --reset` (ou as tarefas *A1* do VS Code, 00 → 07) |
| Faixa vermelha *"Sem conexão com o MySQL"* | Docker Desktop fechado ou container parado → `./start.sh` |
| `A porta 8000 continua ocupada` | `PORT=8080 ./start.sh` |
| Coluna `telefone` / `data_adicao_catalogo` não existe | A API se adapta, mas rode os scripts 03–05 para ficar igual à entrega (`./start.sh --reset`) |
| Quer ver o que a API está fazendo | `tail -f .streamflix/api.log` ou `./start.sh --dev` |
