"""
Todos os templates de prompt centralizados aqui.
Nenhum prompt deve ser hardcoded em llm_service.py.
"""

from typing import Any


# ---------------------------------------------------------------------------
# Camada 1 — NER (Reconhecimento de Entidades Nomeadas)
# ---------------------------------------------------------------------------

NER_SYSTEM_PROMPT = """Você é um especialista em extração de entidades jurídicas e contábeis.
Sua única função é analisar a consulta do usuário e retornar um JSON **válido e completo** com as entidades identificadas.

Regras obrigatórias:
1. Retorne APENAS o objeto JSON, sem texto adicional, sem markdown, sem explicações.
2. Use null para campos não encontrados.
3. Os campos possíveis são:
   - tipo_acao: string (ex: "despejo", "cobrança", "execução fiscal", "inventário")
   - autor: string (nome do autor/requerente)
   - reu: string (nome do réu/requerido)
   - ano: integer (ano do processo ou do fato)
   - numero_processo: string (número CNJ se mencionado, ex: "1234567-89.2024.8.26.0001")
   - valor_causa: float (valor em reais, sem símbolo)
   - comarca: string (cidade/comarca)
   - extras: objeto com quaisquer outras entidades relevantes encontradas

Exemplo de saída:
{"tipo_acao": "despejo", "autor": "Condomínio Edifício Central", "reu": "Adriano", "ano": 2026,
 "numero_processo": null, "valor_causa": null, "comarca": null, "extras": {}}"""


def build_ner_user_prompt(query: str) -> str:
    return f'Extraia as entidades jurídicas da seguinte consulta:\n\n"{query}"'


# ---------------------------------------------------------------------------
# Camada 2 — Geração de SQL
# ---------------------------------------------------------------------------

_SQL_SYSTEM_BASE = """Gere APENAS uma query PostgreSQL SELECT válida. NENHUMA palavra a mais. SEM formatação markdown (```).

Regras:
1. Somente leitura (Proibido DROP/DELETE/UPDATE/INSERT).
2. Use ILIKE para texto.
3. Ignore parâmetros null.
4. Prefira JOINs.
5. Adicione LIMIT 100.""" 

_SQL_SYSTEM_NO_CONTEXT = """
Schema disponível: não fornecido. Use tabelas genéricas: processos, partes, movimentacoes.
Suponha colunas razoáveis para o domínio jurídico."""

_SQL_SYSTEM_WITH_CONTEXT = """
Schema disponível:
{schema}

Dados de exemplo:
{sample_data}"""


def build_sql_system_prompt(db_context: dict[str, Any] | None) -> str:
    if not db_context or (not db_context.get("tables") and not db_context.get("sample_data")):
        return _SQL_SYSTEM_BASE + _SQL_SYSTEM_NO_CONTEXT

    schema_str = _format_schema(db_context.get("tables", {}))
    sample_str = _format_sample_data(db_context.get("sample_data", {}))
    suffix = _SQL_SYSTEM_WITH_CONTEXT.format(schema=schema_str, sample_data=sample_str)
    return _SQL_SYSTEM_BASE + suffix


def build_sql_user_prompt(entities_json: str, original_query: str) -> str:
    return (
        f"Consulta original do usuário: \"{original_query}\"\n\n"
        f"Entidades extraídas (JSON):\n{entities_json}\n\n"
        "Gere a query SQL SELECT para recuperar os registros correspondentes."
    )


# ---------------------------------------------------------------------------
# Helpers internos
# ---------------------------------------------------------------------------

def _format_schema(tables: dict[str, Any]) -> str:
    if not tables:
        return "(sem schema fornecido)"
    lines = []
    for table, columns in tables.items():
        if isinstance(columns, list):
            cols = ", ".join(str(c) for c in columns)
            lines.append(f"  {table}({cols})")
        else:
            lines.append(f"  {table}: {columns}")
    return "\n".join(lines)


def _format_sample_data(sample_data: dict[str, list[dict[str, Any]]]) -> str:
    if not sample_data:
        return "(sem dados de exemplo)"
    lines = []
    for table, rows in sample_data.items():
        lines.append(f"  Tabela {table}:")
        for row in rows[:3]:  # no máximo 3 linhas de exemplo
            lines.append(f"    {row}")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Camada 3 — Resumo Jurídico
# ---------------------------------------------------------------------------

SUMMARY_SYSTEM_PROMPT = """Gere um resumo simplificado em um parágrafo curto para um público geral. Entregue apenas o texto resumido, sem formatações."""


def build_summary_user_prompt(process_data: str) -> str:
    return f"Faça um resumo das seguintes informações processuais:\n\n{process_data}"
