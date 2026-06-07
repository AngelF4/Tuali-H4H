"""
app/services/data_service.py
-----------------------------
Carga los CSVs una sola vez al arrancar y expone
los resultados de todos los módulos como un dict listo
para pasarle a Gemini o devolver al frontend.

Los datos se cachean en memoria — no se recalculan en cada request.
"""

import os
import sys
import pandas as pd
import numpy as np

# Permite importar los módulos del ingeniero desde /modules
_MODULES_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "modules")
sys.path.insert(0, os.path.abspath(_MODULES_PATH))

# Parche para que metas.py encuentre su import interno
import sustituciones as _sust_mod
import types as _types
if "modules" not in sys.modules:
    sys.modules["modules"] = _types.ModuleType("modules")
sys.modules["modules.sustituciones"] = _sust_mod

from data_loader import cargar_datos
from analisis_ventas import AnalizadorVentas
from sustituciones import AnalizadorSustituciones
from prediccion import PredictorVentas
from metas import MotorMetas

# ── Rutas ─────────────────────────────────────────────────
_DATA_DIR       = os.path.join(os.path.dirname(__file__), "..", "..", "data")
PATH_ORDERS     = os.path.join(_DATA_DIR, "Orders.csv")
PATH_RESULTADOS = os.path.join(_DATA_DIR, "Resultados.csv")
PATH_MODELO     = os.path.join(os.path.dirname(__file__), "..", "..", "models", "predictor.pkl")

# ── Cache global ──────────────────────────────────────────
_cache: dict = {}


def get_reporte() -> dict:
    """
    Devuelve el reporte completo del negocio.
    Se calcula solo la primera vez; después se sirve desde cache.
    """
    if _cache:
        return _cache

    _cargar_y_calcular()
    return _cache


def _cargar_y_calcular():
    """Carga datos, corre todos los módulos y guarda en _cache."""
    orders_mx, resultados_mx = cargar_datos(PATH_ORDERS, PATH_RESULTADOS)

    # ── Ventas ────────────────────────────────────────────
    av = AnalizadorVentas(orders_mx)
    reporte_ventas = av.reporte_completo()

    # ── Sustituciones ─────────────────────────────────────
    sust = AnalizadorSustituciones(resultados_mx)
    reporte_sust = sust.reporte_completo()

    # ── Predicción ────────────────────────────────────────
    predictor = PredictorVentas()
    os.makedirs(os.path.dirname(PATH_MODELO), exist_ok=True)
    if os.path.exists(PATH_MODELO):
        predictor.cargar(PATH_MODELO)
    else:
        predictor.entrenar(orders_mx)
        predictor.guardar(PATH_MODELO)
    reporte_pred = predictor.predecir(n_bloques=5)

    # ── Metas ─────────────────────────────────────────────
    motor = MotorMetas(orders_mx, resultados_mx)
    metas = motor.sugerir_metas()

    # ── Anomalías ─────────────────────────────────────────
    entregados = orders_mx[orders_mx["status_final"] == "Entregado"].copy()
    entregados["Total"] = pd.to_numeric(entregados["Total"], errors="coerce")
    mean_t = entregados["Total"].mean()
    std_t  = entregados["Total"].std()
    anomalias_df = entregados[entregados["Total"] > mean_t + 3 * std_t]
    anomalias = [
        {
            "id_pedido": str(r["id_pedido"]),
            "total":     round(float(r["Total"]), 2),
            "cedis":     str(r["cedis"]),
            "desviaciones_sobre_media": round((float(r["Total"]) - mean_t) / std_t, 1),
        }
        for _, r in anomalias_df.head(10).iterrows()
    ]

    # ── Tasa de sustitución global ────────────────────────
    tasa_sust_global = round(len(resultados_mx) / len(orders_mx) * 100, 1)

    # ── Productos problemáticos (alta tasa de sustitución) ─
    sust_por_prod = (
        resultados_mx.groupby("nombre_sku_solicitado")
        .size()
        .reset_index(name="n_sustituciones")
        .sort_values("n_sustituciones", ascending=False)
    )
    total_ped = len(orders_mx)
    productos_problematicos = [
        {
            "producto":          str(r["nombre_sku_solicitado"]),
            "n_sustituciones":   int(r["n_sustituciones"]),
            "tasa_sustitucion_pct": round(int(r["n_sustituciones"]) / total_ped * 100, 2),
        }
        for _, r in sust_por_prod.head(10).iterrows()
    ]

    # ── Recomendación de inventario ───────────────────────
    # Productos críticos + sus sustitutos de alta confianza
    criticos = reporte_sust["productos_criticos"][:5]
    alta_conf = reporte_sust["alta_confianza"]
    inventario_recomendado = {
        "priorizar_stock": [
            {
                "producto":           c["producto"],
                "veces_agotado":      c["veces_agotado"],
                "riesgo":             "alto" if c["veces_agotado"] > 200 else "medio",
                "n_sustitutos":       c["n_sustitutos_distintos"],
                "sustitucion_clara":  c["confianza_principal_pct"] >= 70,
            }
            for c in criticos
        ],
        "sustituciones_automatizables": len(alta_conf),
        "pares_alta_confianza":         alta_conf[:5],
    }

    # ── Optimización de sustituciones ────────────────────
    # Pares que se pueden estandarizar vs los que necesitan atención
    cruzadas = reporte_sust["cruzadas"]
    optimizacion_sust = {
        "automatizables":        alta_conf[:10],
        "cruzadas_de_marca":     cruzadas[:5],
        "total_cruzadas":        len(cruzadas),
        "pct_misma_marca":       reporte_sust["kpis"]["misma_marca_pct"],
    }

    # ── Guardar todo en cache ─────────────────────────────
    _cache.update({
        "ventas":                   reporte_ventas,
        "sustituciones":            reporte_sust,
        "prediccion":               reporte_pred,
        "metas":                    metas,
        "anomalias":                anomalias,
        "tasa_sustitucion_global":  tasa_sust_global,
        "productos_problematicos":  productos_problematicos,
        "inventario_recomendado":   inventario_recomendado,
        "optimizacion_sustituciones": optimizacion_sust,
    })