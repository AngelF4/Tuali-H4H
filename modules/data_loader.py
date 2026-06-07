"""
data_loader.py
--------------
Carga y filtra los CSVs para México.
Lógica de filtro:
  - Orders.csv     → columna 'pais' == 'México'
  - Resultados.csv → columna 'id_businessunit' IN [1, 2]
    (BU 1 = Bebidas, BU 2 = Papitas — únicos de México)
"""

import pandas as pd
import numpy as np


# ── Constantes ────────────────────────────────────────────
PAIS_MEXICO = "México"
BU_MEXICO   = [1, 2]          # business units de México


def cargar_datos(path_orders: str, path_resultados: str):
    """
    Carga y filtra ambos CSVs.

    Retorna
    -------
    orders_mx : pd.DataFrame
        Pedidos de México ordenados por id_pedido (proxy temporal).
    resultados_mx : pd.DataFrame
        Sustituciones de México.
    """
    orders_mx     = _cargar_orders(path_orders)
    resultados_mx = _cargar_resultados(path_resultados)
    return orders_mx, resultados_mx


# ── Privadas ──────────────────────────────────────────────

def _cargar_orders(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, encoding="utf-8", on_bad_lines="skip", dtype=str)

    # Filtro México
    df = df[df["pais"] == PAIS_MEXICO].copy()

    # Tipos numéricos
    df["Total"]        = pd.to_numeric(df["Total"],        errors="coerce")
    df["SubTotal"]     = pd.to_numeric(df["SubTotal"],     errors="coerce")
    df["valor_pedido"] = pd.to_numeric(df["valor_pedido"], errors="coerce")
    df["cedis"]        = pd.to_numeric(df["cedis"],        errors="coerce")

    # id_pedido como número para ordenar cronológicamente
    # (las fechas originales están corruptas; el ID es el proxy temporal)
    df["id_pedido_num"] = pd.to_numeric(
        df["id_pedido"].str.replace("E+", "e+", regex=False),
        errors="coerce"
    )

    df = df.sort_values("id_pedido_num").reset_index(drop=True)
    df["orden_temporal"] = range(len(df))

    return df


def _cargar_resultados(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, encoding="utf-8", on_bad_lines="skip")

    # Filtro México por business unit
    df = df[df["id_businessunit"].isin(BU_MEXICO)].copy()
    df = df.reset_index(drop=True)

    return df
