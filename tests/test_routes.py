import os
os.environ["GEMINI_API_KEY"] = "test"
os.environ["ENVIRONMENT"] = "development"

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health():
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_resumen():
    r = client.get("/api/v1/resumen")
    assert r.status_code == 200
    d = r.json()
    assert d["modulo"] == "resumen_general"
    assert "interpretacion" in d
    assert "datos" in d


def test_ventas():
    r = client.get("/api/v1/ventas")
    assert r.status_code == 200
    assert r.json()["modulo"] == "reporte_ventas"


def test_prediccion():
    r = client.get("/api/v1/prediccion")
    assert r.status_code == 200
    datos = r.json()["datos"]
    assert "bloques" in datos
    assert len(datos["bloques"]) == 5


def test_metas():
    r = client.get("/api/v1/metas")
    assert r.status_code == 200
    datos = r.json()["datos"]
    assert "sugerencias" in datos
    assert len(datos["sugerencias"]) == 3


def test_meta_personalizada():
    r = client.post("/api/v1/metas/personalizada", json={"ticket_objetivo": 4500.0})
    assert r.status_code == 200
    d = r.json()
    assert "ticket_actual" in d
    assert "incremento_pct" in d


def test_estrategias():
    r = client.get("/api/v1/estrategias")
    assert r.status_code == 200


def test_inventario():
    r = client.get("/api/v1/inventario")
    assert r.status_code == 200
    datos = r.json()["datos"]
    assert "priorizar_stock" in datos


def test_anomalias():
    r = client.get("/api/v1/anomalias")
    assert r.status_code == 200
    datos = r.json()["datos"]
    assert datos["total_anomalias"] > 0


def test_sustituciones():
    r = client.get("/api/v1/sustituciones")
    assert r.status_code == 200


def test_productos_problematicos():
    r = client.get("/api/v1/productos-problematicos")
    assert r.status_code == 200
    datos = r.json()["datos"]
    assert len(datos["productos"]) > 0