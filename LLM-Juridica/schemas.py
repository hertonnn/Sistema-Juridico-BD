from pydantic import BaseModel, Field
from typing import Any


class DbContext(BaseModel):
    """Schema opcional do banco de dados para guiar a geração de SQL."""
    tables: dict[str, Any] = Field(
        default_factory=dict,
        description="Mapa de nome_tabela -> lista de colunas ou descrição",
        examples=[{"processos": ["id", "numero", "tipo_acao", "ano", "autor_id", "reu_id"]}],
    )
    sample_data: dict[str, list[dict[str, Any]]] = Field(
        default_factory=dict,
        description="Linhas de exemplo por tabela para contextualizar o modelo",
    )


class SearchRequest(BaseModel):
    """Payload de entrada da rota /search."""
    query: str = Field(
        ...,
        min_length=3,
        max_length=2000,
        description="Consulta em linguagem natural",
        examples=["Ação de despejo do Condomínio Edifício Central contra o Adriano em 2026"],
    )
    db_context: DbContext | None = Field(
        default=None,
        description="Contexto opcional do banco de dados (schema e exemplos)",
    )


class ExtractedEntities(BaseModel):
    """Entidades extraídas pela Camada 1 (NER)."""
    tipo_acao: str | None = None
    autor: str | None = None
    reu: str | None = None
    ano: int | None = None
    numero_processo: str | None = None
    valor_causa: float | None = None
    comarca: str | None = None
    extras: dict[str, Any] = Field(default_factory=dict)


class SearchResponse(BaseModel):
    """Resposta da rota /search."""
    original_query: str
    entities: ExtractedEntities
    sql_query: str
    warning: str | None = Field(
        default=None,
        description="Aviso caso a geração precise de revisão manual",
    )


class SummaryRequest(BaseModel):
    """Payload de entrada da rota /summary."""
    process_data: str = Field(
        ...,
        min_length=10,
        description="Informações ou andamentos do processo para serem resumidos",
        examples=["O juiz proferiu sentença julgando procedente o pedido do autor para condenar o réu ao pagamento de R$ 10.000,00 referente aos danos materiais comprovados nos autos."],
    )


class SummaryResponse(BaseModel):
    """Resposta da rota /summary."""
    summary: str = Field(
        ...,
        description="Resumo jurídico gerado pelo LLM",
    )
