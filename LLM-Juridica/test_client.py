"""
Script de teste local para a API NL-to-SQL.
Execute com: python test_client.py
A API deve estar rodando em http://localhost:8000
"""

import json
import sys
import requests

BASE_URL = "http://localhost:8000"


def print_separator(title: str = "") -> None:
    line = "─" * 60
    if title:
        print(f"\n{line}")
        print(f"  {title}")
        print(line)
    else:
        print(line)


def test_health() -> bool:
    print_separator("Health Check")
    try:
        resp = requests.get(f"{BASE_URL}/health", timeout=5)
        resp.raise_for_status()
        print(f"Status: {resp.json()}")
        return True
    except requests.exceptions.ConnectionError:
        print("ERRO: API não está rodando. Inicie com: uvicorn main:app --reload")
        return False
    except Exception as exc:
        print(f"ERRO inesperado: {exc}")
        return False


def test_acao_despejo() -> None:
    print_separator("Teste 1 — Ação de Despejo")

    payload = {
        "query": "Ação de despejo do Condomínio Edifício Central contra o Adriano em 2026",
        "db_context": {
            "tables": {
                "processos": [
                    "id",
                    "numero_cnj",
                    "tipo_acao",
                    "ano_distribuicao",
                    "valor_causa",
                    "comarca",
                    "status",
                    "autor_id",
                    "reu_id",
                ],
                "partes": [
                    "id",
                    "nome",
                    "cpf_cnpj",
                    "tipo",          # 'PF' ou 'PJ'
                    "email",
                    "telefone",
                ],
            },
            "sample_data": {
                "processos": [
                    {
                        "id": 1,
                        "numero_cnj": "0001234-55.2026.8.26.0001",
                        "tipo_acao": "despejo",
                        "ano_distribuicao": 2026,
                        "valor_causa": 15000.00,
                        "comarca": "São Paulo",
                        "status": "em andamento",
                        "autor_id": 10,
                        "reu_id": 20,
                    }
                ],
                "partes": [
                    {"id": 10, "nome": "Condomínio Edifício Central", "tipo": "PJ"},
                    {"id": 20, "nome": "Adriano Silva", "tipo": "PF"},
                ],
            },
        },
    }

    _run_request(payload)


def test_execucao_fiscal() -> None:
    print_separator("Teste 2 — Execução Fiscal sem db_context")

    payload = {
        "query": "Todas as execuções fiscais da Fazenda Estadual de SP com valor acima de 50 mil reais em 2025",
    }

    _run_request(payload)


def test_inventario() -> None:
    print_separator("Teste 3 — Inventário com número de processo")

    payload = {
        "query": "Processo de inventário número 0009876-12.2024.8.26.0100",
        "db_context": {
            "tables": {
                "processos": ["id", "numero_cnj", "tipo_acao", "ano_distribuicao", "autor_id"],
                "partes": ["id", "nome", "cpf_cnpj"],
            },
            "sample_data": {},
        },
    }

    _run_request(payload)


def _run_request(payload: dict) -> None:
    try:
        resp = requests.post(
            f"{BASE_URL}/search",
            json=payload,
            timeout=120,
        )
    except requests.exceptions.Timeout:
        print("ERRO: Timeout — o modelo demorou mais de 120s para responder.")
        return
    except requests.exceptions.ConnectionError:
        print("ERRO: Não foi possível conectar à API.")
        return

    print(f"HTTP Status: {resp.status_code}")

    if resp.status_code == 200:
        data = resp.json()
        print("\nEntidades extraídas:")
        print(json.dumps(data.get("entities", {}), indent=2, ensure_ascii=False))
        print("\nSQL gerado:")
        print(data.get("sql_query", "(vazio)"))
        if data.get("warning"):
            print(f"\n[AVISO] {data['warning']}")
    else:
        print("\nResposta de erro:")
        try:
            print(json.dumps(resp.json(), indent=2, ensure_ascii=False))
        except Exception:
            print(resp.text)


def test_summary() -> None:
    print_separator("Teste 4 — Resumo Jurídico")

    payload = {
        "process_data": "O juiz proferiu sentença julgando procedente o pedido do autor João da Silva para condenar o réu Banco XY S.A. ao pagamento de R$ 10.000,00 referente aos danos materiais comprovados nos autos. Custas processuais e honorários advocatícios fixados em 10% sobre o valor da condenação a cargo do réu. Processo transitado em julgado em 01/03/2026."
    }

    _run_summary_request(payload)


def _run_summary_request(payload: dict) -> None:
    try:
        resp = requests.post(
            f"{BASE_URL}/summary",
            json=payload,
            timeout=120,
        )
    except requests.exceptions.Timeout:
        print("ERRO: Timeout — o modelo demorou mais de 120s para responder.")
        return
    except requests.exceptions.ConnectionError:
        print("ERRO: Não foi possível conectar à API.")
        return

    print(f"HTTP Status: {resp.status_code}")

    if resp.status_code == 200:
        data = resp.json()
        print("\nResumo gerado:")
        print(data.get("summary", "(vazio)"))
    else:
        print("\nResposta de erro:")
        try:
            print(json.dumps(resp.json(), indent=2, ensure_ascii=False))
        except Exception:
            print(resp.text)



def main() -> None:
    print("=" * 60)
    print("  NL-to-SQL API — Cliente de Teste")
    print("=" * 60)

    if not test_health():
        sys.exit(1)

    #test_acao_despejo()
    #test_execucao_fiscal()
    #test_inventario()
    test_summary()

    print_separator()
    print("Testes concluídos.")


if __name__ == "__main__":
    main()
