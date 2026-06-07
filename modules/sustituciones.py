"""
sustituciones.py
----------------
Análisis de patrones de sustitución de productos para México.

Aprende automáticamente de los datos reales:
  - qué productos se agotan más
  - qué productos se usan como sustituto
  - qué pares tienen alta confianza (relación predecible)
  - qué productos tienen sustituciones cruzadas de marca

No usa reglas manuales — todo sale de frecuencias reales.

Uso
---
    from modules.sustituciones import AnalizadorSustituciones

    sust = AnalizadorSustituciones(resultados_mx)
    print(sust.top_pares())
    print(sust.pares_alta_confianza())
    print(sust.productos_criticos())
    print(sust.reporte_completo())
"""

import pandas as pd
import numpy as np


class AnalizadorSustituciones:

    def __init__(self, resultados_mx: pd.DataFrame):
        """
        Parámetros
        ----------
        resultados_mx : DataFrame filtrado por México (de data_loader)
        """
        self._df = resultados_mx.copy()
        self._calcular_misma_marca()
        self._pares = self._calcular_pares()

    # ── KPIs generales ────────────────────────────────────

    def kpis(self) -> dict:
        """
        Retorna métricas generales del sistema de sustituciones.
        """
        df = self._df
        return {
            "total_sustituciones":    int(len(df)),
            "skus_agotados_unicos":   int(df["sku_solicitado"].nunique()),
            "skus_sustitutos_unicos": int(df["sku_solicitado_cambio"].nunique()),
            "misma_marca_pct":        round(df["misma_marca"].mean() * 100, 1),
            "marca_cruzada_pct":      round((~df["misma_marca"]).mean() * 100, 1),
        }

    # ── Top pares de sustitución ──────────────────────────

    def top_pares(self, top_n: int = 15, min_ocurrencias: int = 1) -> list[dict]:
        """
        Pares más frecuentes de (producto_agotado → sustituto).

        Parámetros
        ----------
        top_n          : cuántos pares devolver
        min_ocurrencias: filtrar pares con menos de N ocurrencias

        Retorna
        -------
        [{producto_agotado, sustituto, frecuencia, confianza_pct, misma_marca}]
        """
        pares = self._pares[self._pares["frecuencia"] >= min_ocurrencias]
        pares = pares.sort_values("frecuencia", ascending=False).head(top_n)

        return [
            {
                "producto_agotado": r["nombre_sku_solicitado"],
                "sustituto":        r["nombre_sku_solicitado_cambio"],
                "frecuencia":       int(r["frecuencia"]),
                "confianza_pct":    float(r["confianza"]),
                "misma_marca":      bool(r["misma_marca"]),
            }
            for _, r in pares.iterrows()
        ]

    # ── Pares con alta confianza ──────────────────────────

    def pares_alta_confianza(
        self,
        min_confianza: float = 80.0,
        min_ocurrencias: int = 5,
    ) -> list[dict]:
        """
        Pares donde la sustitución es altamente predecible.
        Confianza = % de veces que, dado que falta A, se elige B.

        Estos pares pueden automatizarse en el backend sin
        intervención humana.

        Parámetros
        ----------
        min_confianza   : umbral de confianza (default 80%)
        min_ocurrencias : mínimo de veces para considerar el par

        Retorna
        -------
        [{producto_agotado, sustituto, frecuencia, confianza_pct}]
        """
        pares = self._pares[
            (self._pares["frecuencia"] >= min_ocurrencias) &
            (self._pares["confianza"]  >= min_confianza)
        ].sort_values("confianza", ascending=False)

        return [
            {
                "producto_agotado": r["nombre_sku_solicitado"],
                "sustituto":        r["nombre_sku_solicitado_cambio"],
                "frecuencia":       int(r["frecuencia"]),
                "confianza_pct":    float(r["confianza"]),
            }
            for _, r in pares.iterrows()
        ]

    # ── Productos críticos (más agotados) ─────────────────

    def productos_criticos(self, top_n: int = 15) -> list[dict]:
        """
        Productos que se agotan con más frecuencia, junto con
        cuántos sustitutos distintos tienen.

        Un producto crítico con muchos sustitutos distintos indica
        que no hay un reemplazo claro → priorizar su inventario.

        Retorna
        -------
        [{producto, veces_agotado, n_sustitutos_distintos, sustituto_principal, confianza_principal_pct}]
        """
        df = self._df

        # Veces que se agotó cada producto
        agotados = (
            df.groupby("nombre_sku_solicitado")
            .size()
            .reset_index(name="veces_agotado")
            .sort_values("veces_agotado", ascending=False)
            .head(top_n)
        )

        # Diversidad de sustitutos
        diversidad = (
            df.groupby("nombre_sku_solicitado")["nombre_sku_solicitado_cambio"]
            .nunique()
            .reset_index()
        )
        diversidad.columns = ["nombre_sku_solicitado", "n_sustitutos_distintos"]

        # Sustituto principal (el más frecuente para ese producto)
        sustituto_top = (
            self._pares.sort_values("frecuencia", ascending=False)
            .groupby("nombre_sku_solicitado")
            .first()
            .reset_index()
            [["nombre_sku_solicitado", "nombre_sku_solicitado_cambio", "confianza"]]
        )
        sustituto_top.columns = [
            "nombre_sku_solicitado", "sustituto_principal", "confianza_principal"
        ]

        merged = (
            agotados
            .merge(diversidad, on="nombre_sku_solicitado", how="left")
            .merge(sustituto_top, on="nombre_sku_solicitado", how="left")
        )

        return [
            {
                "producto":               r["nombre_sku_solicitado"],
                "veces_agotado":          int(r["veces_agotado"]),
                "n_sustitutos_distintos": int(r["n_sustitutos_distintos"]),
                "sustituto_principal":    str(r["sustituto_principal"]),
                "confianza_principal_pct":round(float(r["confianza_principal"]), 1),
            }
            for _, r in merged.iterrows()
        ]

    # ── Sustitutos más versátiles ─────────────────────────

    def sustitutos_top(self, top_n: int = 10) -> list[dict]:
        """
        Productos más usados como sustituto — son los que el
        negocio realmente tiene cuando todo lo demás falla.

        Retorna
        -------
        [{sustituto, veces_usado_como_sustituto}]
        """
        top = (
            self._df.groupby("nombre_sku_solicitado_cambio")
            .size()
            .reset_index(name="veces_como_sustituto")
            .sort_values("veces_como_sustituto", ascending=False)
            .head(top_n)
        )
        return [
            {
                "sustituto":              r["nombre_sku_solicitado_cambio"],
                "veces_usado_como_sustituto": int(r["veces_como_sustituto"]),
            }
            for _, r in top.iterrows()
        ]

    # ── Sustituciones cruzadas de marca ───────────────────

    def sustituciones_cruzadas(self) -> list[dict]:
        """
        Sustituciones donde el producto de reemplazo es de
        distinta marca — señal de pérdida potencial de lealtad.

        Retorna
        -------
        [{producto_agotado, sustituto, frecuencia}]
        """
        cruzadas = self._df[~self._df["misma_marca"]].copy()
        agg = (
            cruzadas.groupby(["nombre_sku_solicitado", "nombre_sku_solicitado_cambio"])
            .size()
            .reset_index(name="frecuencia")
            .sort_values("frecuencia", ascending=False)
        )
        return [
            {
                "producto_agotado": r["nombre_sku_solicitado"],
                "sustituto":        r["nombre_sku_solicitado_cambio"],
                "frecuencia":       int(r["frecuencia"]),
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
            "kpis":                self.kpis(),
            "top_pares":           self.top_pares(),
            "alta_confianza":      self.pares_alta_confianza(),
            "productos_criticos":  self.productos_criticos(),
            "sustitutos_top":      self.sustitutos_top(),
            "cruzadas":            self.sustituciones_cruzadas(),
        }

    # ── Privados ──────────────────────────────────────────

    def _calcular_misma_marca(self):
        """Agrega columna booleana: ¿sustituto es de la misma marca?"""
        def _misma(row):
            orig = str(row["nombre_sku_solicitado"]).strip().split()[0].lower()
            sust = str(row["nombre_sku_solicitado_cambio"]).strip().split()[0].lower()
            return orig == sust
        self._df["misma_marca"] = self._df.apply(_misma, axis=1)

    def _calcular_pares(self) -> pd.DataFrame:
        """
        Calcula frecuencia y confianza de cada par (agotado → sustituto).
        Confianza = frecuencia_par / total_veces_agotado_ese_producto
        """
        df = self._df

        # Frecuencia de cada par
        pares = (
            df.groupby(["nombre_sku_solicitado", "nombre_sku_solicitado_cambio"])
            .agg(
                frecuencia =("nombre_sku_solicitado", "count"),
                misma_marca=("misma_marca", "first"),
            )
            .reset_index()
        )

        # Total de veces agotado por producto
        total_por_prod = (
            df.groupby("nombre_sku_solicitado")
            .size()
            .reset_index(name="total_agotado")
        )
        pares = pares.merge(total_por_prod, on="nombre_sku_solicitado", how="left")
        pares["confianza"] = (
            pares["frecuencia"] / pares["total_agotado"] * 100
        ).round(1)

        return pares
