"""
analisis_ventas.py
------------------
Análisis estadístico de ventas para México.

No usa modelos ML — puro pandas con métricas reales de los datos.

Uso
---
    from modules.analisis_ventas import AnalizadorVentas

    analizador = AnalizadorVentas(orders_mx)
    print(analizador.kpis())
    print(analizador.tendencia(bloque=1000))
    print(analizador.por_cedis(top_n=10))
    print(analizador.segmentacion())
    print(analizador.reporte_completo())
"""

import pandas as pd
import numpy as np


# Rangos de segmentación por tamaño de pedido
SEGMENTOS_BINS   = [0, 500, 1000, 2000, 5000, 10000, float("inf")]
SEGMENTOS_LABELS = ["<$500", "$500-1k", "$1k-2k", "$2k-5k", "$5k-10k", ">$10k"]


class AnalizadorVentas:

    def __init__(self, orders_mx: pd.DataFrame):
        """
        Parámetros
        ----------
        orders_mx : DataFrame filtrado por México (de data_loader)
        """
        self._df       = orders_mx
        self._entregados = orders_mx[orders_mx["status_final"] == "Entregado"].copy()

    # ── KPIs generales ────────────────────────────────────

    def kpis(self) -> dict:
        """
        Retorna los indicadores clave de desempeño.

        Retorna
        -------
        {
          total_pedidos, entregados, rechazados, cancelados, registrados,
          tasa_entrega_pct, venta_total, ticket_promedio, ticket_mediana,
          ticket_maximo, ticket_minimo, ticket_std
        }
        """
        df  = self._df
        ent = self._entregados

        return {
            "total_pedidos":    int(len(df)),
            "entregados":       int((df["status_final"] == "Entregado").sum()),
            "rechazados":       int((df["status_final"] == "Rechazado").sum()),
            "cancelados":       int((df["status_final"] == "Cancelado").sum()),
            "registrados":      int((df["status_final"] == "Registrado").sum()),
            "tasa_entrega_pct": round((df["status_final"] == "Entregado").mean() * 100, 2),
            "venta_total":      round(float(ent["Total"].sum()), 2),
            "ticket_promedio":  round(float(ent["Total"].mean()), 2),
            "ticket_mediana":   round(float(ent["Total"].median()), 2),
            "ticket_maximo":    round(float(ent["Total"].max()), 2),
            "ticket_minimo":    round(float(ent["Total"].min()), 2),
            "ticket_std":       round(float(ent["Total"].std()), 2),
        }

    # ── Tendencia temporal ────────────────────────────────

    def tendencia(self, bloque: int = 1000) -> list[dict]:
        """
        Agrupa pedidos entregados en bloques de N para ver la tendencia
        del ticket promedio a lo largo del historial.

        Parámetros
        ----------
        bloque : tamaño del bloque (default 1000 pedidos)

        Retorna
        -------
        Lista de dicts: [{bloque, pedidos, venta_total, ticket_promedio}]
        """
        ent = self._entregados.sort_values("id_pedido_num").reset_index(drop=True)
        ent["bloque_idx"] = ent.index // bloque

        resultado = (
            ent.groupby("bloque_idx")
            .agg(
                pedidos      =("Total", "count"),
                venta_total  =("Total", "sum"),
                ticket_prom  =("Total", "mean"),
            )
            .reset_index()
        )

        return [
            {
                "bloque":         int(r["bloque_idx"]) + 1,
                "pedidos":        int(r["pedidos"]),
                "venta_total":    round(float(r["venta_total"]), 2),
                "ticket_promedio":round(float(r["ticket_prom"]), 2),
            }
            for _, r in resultado.iterrows()
        ]

    # ── Por CEDIS ─────────────────────────────────────────

    def por_cedis(self, top_n: int = 10) -> list[dict]:
        """
        Ranking de CEDIS por venta total.

        Retorna
        -------
        Lista de dicts: [{cedis, pedidos, venta_total, ticket_promedio, pct_venta}]
        """
        ent = self._entregados
        agg = (
            ent.groupby("cedis")
            .agg(
                pedidos      =("Total", "count"),
                venta_total  =("Total", "sum"),
                ticket_prom  =("Total", "mean"),
            )
            .sort_values("venta_total", ascending=False)
            .head(top_n)
            .reset_index()
        )
        total_venta = agg["venta_total"].sum()

        return [
            {
                "cedis":          str(r["cedis"]),
                "pedidos":        int(r["pedidos"]),
                "venta_total":    round(float(r["venta_total"]), 2),
                "ticket_promedio":round(float(r["ticket_prom"]), 2),
                "pct_venta":      round(float(r["venta_total"] / total_venta * 100), 1),
            }
            for _, r in agg.iterrows()
        ]

    # ── Segmentación por tamaño ───────────────────────────

    def segmentacion(self) -> list[dict]:
        """
        Distribución de pedidos y venta por segmento de precio.

        Retorna
        -------
        Lista de dicts: [{segmento, pedidos, pct_pedidos, venta_total, pct_venta, ticket_promedio}]
        """
        ent = self._entregados.copy()
        ent["segmento"] = pd.cut(
            ent["Total"],
            bins=SEGMENTOS_BINS,
            labels=SEGMENTOS_LABELS,
        )
        agg = (
            ent.groupby("segmento", observed=True)
            .agg(
                pedidos    =("Total", "count"),
                venta_total=("Total", "sum"),
                ticket_prom=("Total", "mean"),
            )
            .reset_index()
        )
        total_ped = agg["pedidos"].sum()
        total_vta = agg["venta_total"].sum()

        return [
            {
                "segmento":       str(r["segmento"]),
                "pedidos":        int(r["pedidos"]),
                "pct_pedidos":    round(float(r["pedidos"] / total_ped * 100), 1),
                "venta_total":    round(float(r["venta_total"]), 2),
                "pct_venta":      round(float(r["venta_total"] / total_vta * 100), 1),
                "ticket_promedio":round(float(r["ticket_prom"]), 2),
            }
            for _, r in agg.iterrows()
        ]

    # ── Reporte completo ──────────────────────────────────

    def reporte_completo(self) -> dict:
        """
        Agrupa todos los análisis en un solo dict.
        Útil para serializar a JSON y enviar a un frontend.
        """
        return {
            "kpis":          self.kpis(),
            "tendencia":     self.tendencia(),
            "cedis":         self.por_cedis(),
            "segmentacion":  self.segmentacion(),
        }
