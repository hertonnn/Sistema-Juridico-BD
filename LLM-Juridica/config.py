from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # --- Camada 1: NER (Reconhecimento de Entidades) ---
    NER_MODEL: str = "ollama/qwen2.5:3B"
    NER_API_BASE: str = "http://localhost:11434"
    NER_API_KEY: str = "ollama"

    # --- Camada 2: Geração de SQL ---
    SQL_MODEL: str = "ollama/qwen2.5:3B"
    SQL_API_BASE: str = "http://localhost:11434"
    SQL_API_KEY: str = "ollama"

    # --- Camada 3: Resumo Jurídico ---
    SUMMARY_MODEL: str = "ollama/qwen2.5:3B"
    SUMMARY_API_BASE: str = "http://localhost:11434"
    SUMMARY_API_KEY: str = "ollama"

    # --- Configurações Gerais ---
    APP_TITLE: str = "NL-to-SQL API (Jurídico/Contábil)"
    APP_VERSION: str = "1.0.0"
    LLM_TEMPERATURE: float = 0.0
    LLM_MAX_TOKENS: int = 1024

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()
