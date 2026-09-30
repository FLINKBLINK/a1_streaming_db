from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from backend.routers import api

BASE_DIR = Path(__file__).resolve().parent.parent

app = FastAPI(
    title="StreamFlix - A1 Banco de Dados",
    description="Webapp para demonstrar e testar o banco streaming_db.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api.router, prefix="/api", tags=["Streaming"])
app.mount("/", StaticFiles(directory=BASE_DIR / "frontend", html=True), name="frontend")
