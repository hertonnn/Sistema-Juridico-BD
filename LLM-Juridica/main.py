import logging

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

from config import get_settings
from llm_service import extract_entities, generate_sql, validate_sql_safety, generate_summary
from schemas import SearchRequest, SearchResponse, SummaryRequest, SummaryResponse

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)

settings = get_settings()

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title=settings.APP_TITLE,
    version=settings.APP_VERSION,
    description=(
        "API que converte linguagem natural em SQL seguro (PostgreSQL) "
        "para contextos jurídicos e contábeis, usando um pipeline de dois estágios de LLM."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permite requisições de qualquer origem
    allow_credentials=True,
    allow_methods=["*"],  # Permite todos os métodos (GET, POST, etc)
    allow_headers=["*"],  # Permite todos os cabeçalhos
)


@app.get("/health", tags=["infra"])
async def health_check() -> dict[str, str]:
    return {"status": "ok", "version": settings.APP_VERSION}


@app.post(
    "/search",
    response_model=SearchResponse,
    tags=["nl-to-sql"],
    summary="Converte linguagem natural em SQL (PostgreSQL)",
    responses={
        422: {"description": "Query SQL gerada é insegura ou inválida"},
        502: {"description": "Erro de comunicação com o modelo de linguagem"},
        503: {"description": "Modelo de linguagem indisponível"},
    },
)
async def search(request: SearchRequest) -> SearchResponse:
    """
    Pipeline de dois estágios:

    1. **NER** — extrai entidades estruturadas da query em linguagem natural.
    2. **SQL Gen** — gera uma query SELECT segura para PostgreSQL.

    A query gerada é validada antes de ser retornada: deve começar com SELECT
    e não pode conter palavras destrutivas (DROP, DELETE, UPDATE, etc.).
    """
    logger.info("Nova requisição /search | query='%s'", request.query[:80])

    # Camada 1: extração de entidades
    entities = await extract_entities(request.query)
    logger.info("Entidades extraídas: %s", entities.model_dump(exclude_none=True))

    # Camada 2: geração de SQL
    sql_query = await generate_sql(
        entities=entities,
        original_query=request.query,
        db_context=request.db_context,
    )
    logger.info("SQL gerado: %s", sql_query[:200])

    # Validação de segurança (bloqueia queries perigosas)
    validate_sql_safety(sql_query)

    warning: str | None = None
    if not request.db_context:
        warning = (
            "Nenhum db_context foi fornecido. "
            "A query foi gerada com base em um schema genérico e pode precisar de ajustes."
        )

    return SearchResponse(
        original_query=request.query,
        entities=entities,
        sql_query=sql_query,
        warning=warning,
    )


@app.post(
    "/summary",
    response_model=SummaryResponse,
    tags=["summary"],
    summary="Gera um resumo jurídico a partir de dados processuais",
    responses={
        502: {"description": "Erro de comunicação com o modelo de linguagem"},
        503: {"description": "Modelo de linguagem indisponível"},
    },
)
async def summary(request: SummaryRequest) -> SummaryResponse:
    """
    Recebe informações brutas ou andamentos de um processo e utiliza o LLM
    para gerar um resumo conciso, destacando as partes, tipo de ação e principais decisões.
    """
    logger.info("Nova requisição /summary | tamanho=%d", len(request.process_data))
    
    resumo_gerado = await generate_summary(request.process_data)
    
    logger.info("Resumo gerado com sucesso.")

    return SummaryResponse(summary=resumo_gerado)



@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc: HTTPException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "status_code": exc.status_code},
    )
