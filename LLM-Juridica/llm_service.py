"""
Lógica das duas camadas de IA:
  Camada 1 — NER: extração de entidades da query em linguagem natural.
  Camada 2 — SQL Gen: geração de SQL a partir das entidades + schema.
"""

import json
import logging
import re
from typing import Any

import litellm
from fastapi import HTTPException

from config import get_settings
from prompts import (
    NER_SYSTEM_PROMPT,
    build_ner_user_prompt,
    build_sql_system_prompt,
    build_sql_user_prompt,
    SUMMARY_SYSTEM_PROMPT,
    build_summary_user_prompt,
)
from schemas import DbContext, ExtractedEntities

logger = logging.getLogger(__name__)

# Palavras destrutivas proibidas na SQL gerada
_DANGEROUS_PATTERN = re.compile(
    r"\b(DROP|DELETE|UPDATE|INSERT|TRUNCATE|ALTER|CREATE|GRANT|REVOKE|EXEC|EXECUTE)\b",
    re.IGNORECASE,
)

_SELECT_START_PATTERN = re.compile(r"^\s*SELECT\b", re.IGNORECASE)


# ---------------------------------------------------------------------------
# Camada 1: NER
# ---------------------------------------------------------------------------

async def extract_entities(query: str) -> ExtractedEntities:
    """Chama o modelo NER para extrair entidades estruturadas da query."""
    settings = get_settings()

    messages = [
        {"role": "system", "content": NER_SYSTEM_PROMPT},
        {"role": "user", "content": build_ner_user_prompt(query)},
    ]

    raw_response = await _call_llm(
        model=settings.NER_MODEL,
        api_base=settings.NER_API_BASE,
        api_key=settings.NER_API_KEY,
        messages=messages,
        label="NER",
    )

    return _parse_ner_response(raw_response)


def _parse_ner_response(raw: str) -> ExtractedEntities:
    """Extrai o JSON da resposta do NER e converte para ExtractedEntities."""
    # Tenta extrair bloco JSON caso o modelo tenha embrulhado em markdown
    json_match = re.search(r"\{.*\}", raw, re.DOTALL)
    if not json_match:
        logger.warning("NER não retornou JSON válido. Resposta bruta: %s", raw)
        raise HTTPException(
            status_code=502,
            detail="Falha na Camada 1 (NER): o modelo não retornou JSON válido.",
        )

    try:
        data: dict[str, Any] = json.loads(json_match.group())
    except json.JSONDecodeError as exc:
        logger.error("Erro ao parsear JSON do NER: %s | Raw: %s", exc, raw)
        raise HTTPException(
            status_code=502,
            detail=f"Falha na Camada 1 (NER): JSON malformado — {exc}",
        ) from exc

    return ExtractedEntities(**{k: v for k, v in data.items() if k in ExtractedEntities.model_fields})


# ---------------------------------------------------------------------------
# Camada 2: Geração de SQL
# ---------------------------------------------------------------------------

async def generate_sql(
    entities: ExtractedEntities,
    original_query: str,
    db_context: DbContext | None,
) -> str:
    """Chama o modelo SQL para gerar a query a partir das entidades."""
    settings = get_settings()

    ctx_dict = db_context.model_dump() if db_context else None
    system_prompt = build_sql_system_prompt(ctx_dict)
    entities_json = entities.model_dump_json(indent=2)
    user_prompt = build_sql_user_prompt(entities_json, original_query)

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

    raw_sql = await _call_llm(
        model=settings.SQL_MODEL,
        api_base=settings.SQL_API_BASE,
        api_key=settings.SQL_API_KEY,
        messages=messages,
        label="SQL-Gen",
    )

    return _clean_sql(raw_sql)


def _clean_sql(raw: str) -> str:
    """Remove markdown e espaços extras da SQL retornada pelo modelo."""
    # Remove blocos ```sql ... ``` ou ``` ... ```
    sql = re.sub(r"```(?:sql)?", "", raw, flags=re.IGNORECASE).strip()
    return sql.strip()


# ---------------------------------------------------------------------------
# Validação de Segurança
# ---------------------------------------------------------------------------

def validate_sql_safety(sql: str) -> None:
    """
    Garante que a SQL gerada:
      1. começa com SELECT
      2. não contém palavras destrutivas
    Lança HTTPException 422 se a validação falhar.
    """
    if not _SELECT_START_PATTERN.match(sql):
        raise HTTPException(
            status_code=422,
            detail=(
                "Segurança: a query gerada não começa com SELECT. "
                f"Início recebido: '{sql[:60]}...'"
            ),
        )

    match = _DANGEROUS_PATTERN.search(sql)
    if match:
        raise HTTPException(
            status_code=422,
            detail=(
                f"Segurança: a query gerada contém a palavra proibida '{match.group().upper()}'. "
                "A query foi bloqueada."
            ),
        )


# ---------------------------------------------------------------------------
# Chamada LLM genérica (via litellm)
# ---------------------------------------------------------------------------

async def _call_llm(
    *,
    model: str,
    api_base: str,
    api_key: str,
    messages: list[dict[str, str]],
    label: str,
) -> str:
    """Wrapper assíncrono sobre litellm.acompletion com tratamento de erros."""
    settings = get_settings()
    logger.info("[%s] Chamando modelo '%s' em '%s'", label, model, api_base)

    try:
        response = await litellm.acompletion(
            model=model,
            messages=messages,
            api_base=api_base,
            api_key=api_key,
            temperature=settings.LLM_TEMPERATURE,
            max_tokens=settings.LLM_MAX_TOKENS,
        )
    except litellm.exceptions.APIConnectionError as exc:
        logger.error("[%s] Erro de conexão com o LLM: %s", label, exc)
        raise HTTPException(
            status_code=503,
            detail=f"[{label}] Não foi possível conectar ao modelo '{model}': {exc}",
        ) from exc
    except litellm.exceptions.AuthenticationError as exc:
        logger.error("[%s] Erro de autenticação: %s", label, exc)
        raise HTTPException(
            status_code=502,
            detail=f"[{label}] Erro de autenticação com o modelo '{model}'.",
        ) from exc
    except Exception as exc:
        logger.error("[%s] Erro inesperado ao chamar o LLM: %s", label, exc)
        raise HTTPException(
            status_code=502,
            detail=f"[{label}] Erro inesperado: {exc}",
        ) from exc

    content: str = response.choices[0].message.content or ""
    logger.debug("[%s] Resposta bruta: %s", label, content)
    return content.strip()


# ---------------------------------------------------------------------------
# Camada 3: Resumo Jurídico
# ---------------------------------------------------------------------------

async def generate_summary(process_data: str) -> str:
    """Chama o modelo para gerar um resumo do processo."""
    settings = get_settings()

    messages = [
        {"role": "system", "content": SUMMARY_SYSTEM_PROMPT},
        {"role": "user", "content": build_summary_user_prompt(process_data)},
    ]

    raw_summary = await _call_llm(
        model=settings.SUMMARY_MODEL,
        api_base=settings.SUMMARY_API_BASE,
        api_key=settings.SUMMARY_API_KEY,
        messages=messages,
        label="Summary",
    )

    return raw_summary
