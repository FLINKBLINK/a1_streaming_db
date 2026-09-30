# A1 Streaming Webapp

Webapp em FastAPI + SQLAlchemy + MySQL para demonstrar o banco `streaming_db`.

## Rodar

1. Na pasta original do banco:
```bash
docker compose up -d
docker compose ps
```

2. Entre nesta pasta `webapp`:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn backend.main:app --reload
```

3. Abra:
http://127.0.0.1:8000

API:
http://127.0.0.1:8000/docs

O webapp usa o MySQL existente em `localhost:3307` e não recria nem altera o banco.
