"""
metas.py
--------
Módulo de metas inteligentes basadas en datos reales.

Flujo:
  1. El sistema analiza el ticket promedio actual y sugiere 3 metas
     (conservadora, moderada, agresiva) calculadas desde distribución real.
  2. El dueño elige o ajusta una meta.
  3. El sistema desglosa la meta en 4 mini-goals (25/50/75/100%)
     con acciones concretas y realistas para cada etapa.
  4. Conforme llegan nuevos pedidos, se puede evaluar el avance.

Uso
---
    from modules.metas import MotorMetas

    motor = MotorMetas(orders_mx)

    # Paso 1 — el sistema sugiere metas
    sugerencias = motor.sugerir_metas()

    # Paso 2 — el dueño elige (o pone la suya)
    meta = motor.definir_meta(ticket_objetivo=4000)

    # Paso 3 — plan con mini-goals y acciones
    plan = motor.generar_plan()

    # Paso 4 — evaluar avance con nuevos pedidos
    avance = motor.evaluar_avance(pedidos_recientes_df)
"""

import pandas as pd
import numpy as np


# ── Umbrales de mini-goals ────────────────────────────────
HITOS = [0.25, 0.50, 0.75, 1.00]
HITOS_LABELS = ["25%", "50%", "75%", "100% ✓"]

# ── Acciones por etapa (se seleccionan según contexto) ────
# Cada acción tiene: descripción, impacto esperado, y condición para activarse
BANCO_ACCIONES = {
    "25": [
        {
            "accion": "Identifica los 10 pedidos más pequeños de la semana y ofrece un producto complementario al momento del pedido.",
            "impacto": "Pedidos pequeños representan el 50% del volumen — moverlos $200 arriba suma rápido.",
            "tipo": "upsell_pequenos",
        },
        {
            "accion": "Activa sustituciones automáticas para los {n_automatizables} pares de alta confianza — evita que el cliente reduzca su pedido por falta de stock.",
            "impacto": "Cada sustitución no resuelta puede costar parte del pedido.",
            "tipo": "sustituciones",
        },
        {
            "accion": "Revisa el inventario de {producto_critico} — es el producto que más se agota y tiene {n_sustitutos} sustitutos distintos, lo que indica pérdida de control.",
            "impacto": "Tener stock del producto más pedido reduce sustituciones y aumenta el ticket.",
            "tipo": "inventario_critico",
        },
    ],
    "50": [
        {
            "accion": "Enfoca esfuerzo en el CEDIS {mejor_cedis} — su ticket promedio (${ticket_mejor_cedis:,.0f}) está {brecha:.0f}% arriba del promedio general. Analiza qué hace diferente.",
            "impacto": "Replicar las prácticas del CEDIS líder en otros puede subir el ticket general.",
            "tipo": "benchmark_cedis",
        },
        {
            "accion": "Ofrece combos o paquetes mínimos de ${umbral_combo:,.0f} para pedidos que históricamente se quedan en ${rango_bajo:,.0f}–${rango_alto:,.0f}.",
            "impacto": "El segmento $1k–$2k representa el 28% del volumen — empujarlos al siguiente nivel es el mayor palanca.",
            "tipo": "combos_segmento",
        },
        {
            "accion": "Contacta a los clientes del CEDIS {peor_cedis} (ticket ${ticket_peor_cedis:,.0f}, brecha de ${brecha_cedis:,.0f} vs el mejor) con una oferta de volumen mínimo.",
            "impacto": "El CEDIS con menor ticket tiene el mayor margen de mejora — un pequeño empujón ahí mueve el promedio general.",
            "tipo": "recuperar_cedis",
        },
    ],
    "75": [
        {
            "accion": "Implementa un mínimo de pedido progresivo: clientes con historial de tickets bajos reciben precio especial si superan ${meta_intermedia:,.0f}.",
            "impacto": "Los pedidos bajos recurrentes son hábito — un incentivo de precio los mueve.",
            "tipo": "minimo_progresivo",
        },
        {
            "accion": "Revisa los {pct_pequenos:.0f}% de pedidos menores a la mediana (${mediana:,.0f}) — clasifícalos por cliente y ofrece seguimiento personalizado.",
            "impacto": "Mover la mitad de esos pedidos $300 arriba equivale a alcanzar casi la meta.",
            "tipo": "clasificar_pequenos",
        },
    ],
    "100": [
        {
            "accion": "Evalúa si el ticket objetivo de ${meta:,.0f} se mantiene en los últimos 500 pedidos. Si sí, sube la meta al siguiente nivel ({siguiente_meta:,.0f}).",
            "impacto": "Una meta alcanzada es el mejor momento para establecer la siguiente.",
            "tipo": "subir_meta",
        },
        {
            "accion": "Documenta qué acciones de las etapas anteriores funcionaron mejor y conviértelas en proceso estándar.",
            "impacto": "Lo que se mide y estandariza se mantiene.",
            "tipo": "estandarizar",
        },
    ],
}


class MotorMetas:
    """
    Motor de metas inteligentes para mejorar el ticket promedio.

    Atributos públicos después de inicializar
    ------------------------------------------
    ticket_actual  : ticket promedio actual del negocio
    ticket_mediana : ticket mediana
    contexto       : dict con métricas clave del negocio (para acciones)
    meta_objetivo  : ticket objetivo (se define con definir_meta())
    """

    def __init__(self, orders_mx: pd.DataFrame, resultados_mx: pd.DataFrame = None):
        self._df          = orders_mx
        self._resultados  = resultados_mx
        self._entregados  = orders_mx[orders_mx["status_final"] == "Entregado"].copy()
        self.meta_objetivo = None
        self._plan        = None

        self._calcular_contexto()

    # ── 1. Sugerir metas ──────────────────────────────────

    def sugerir_metas(self) -> dict:
        """
        Sugiere 3 niveles de meta basados en la distribución real de ventas.

        Retorna
        -------
        {
          ticket_actual,
          tendencia_reciente_pct,
          sugerencias: [
            {nivel, ticket_objetivo, incremento_pct, descripcion}
          ]
        }
        """
        ctx = self.contexto
        t   = ctx["ticket_actual"]

        sugerencias = [
            {
                "nivel":           "conservadora",
                "ticket_objetivo": round(ctx["p75"], 2),
                "incremento_pct":  round((ctx["p75"] / t - 1) * 100, 1),
                "descripcion":     (
                    f"Alcanzar el ticket del 75% de tus mejores pedidos. "
                    f"Ya lo logras en tu CEDIS {ctx['mejor_cedis']} — "
                    f"el objetivo es replicarlo en los demás."
                ),
            },
            {
                "nivel":           "moderada",
                "ticket_objetivo": round((t + ctx["p90"]) / 2, 2),
                "incremento_pct":  round(((t + ctx["p90"]) / 2 / t - 1) * 100, 1),
                "descripcion":     (
                    f"Punto intermedio entre tu promedio actual y tu percentil 90. "
                    f"Requiere mover el {ctx['pct_pequenos']:.0f}% de pedidos pequeños "
                    f"al menos un segmento arriba."
                ),
            },
            {
                "nivel":           "agresiva",
                "ticket_objetivo": round(ctx["p90"], 2),
                "incremento_pct":  round((ctx["p90"] / t - 1) * 100, 1),
                "descripcion":     (
                    f"Igualar el ticket de tu percentil 90. "
                    f"Solo el 10% de tus pedidos lo alcanzan hoy — "
                    f"requiere cambios en mix de productos y política de pedido mínimo."
                ),
            },
        ]

        return {
            "ticket_actual":         round(t, 2),
            "ticket_mediana":        round(ctx["ticket_mediana"], 2),
            "tendencia_reciente_pct":round(ctx["tendencia_pct"], 1),
            "nota_tendencia":        self._interpretar_tendencia(ctx["tendencia_pct"]),
            "sugerencias":           sugerencias,
        }

    # ── 2. Definir meta ───────────────────────────────────

    def definir_meta(self, ticket_objetivo: float) -> dict:
        """
        El dueño define (o confirma) el ticket objetivo.
        Valida que sea realista y ajusta si es necesario.

        Parámetros
        ----------
        ticket_objetivo : el ticket promedio que quiere alcanzar

        Retorna
        -------
        {meta_aceptada, ticket_objetivo, incremento_pct, advertencia?}
        """
        ctx = self.contexto
        t   = ctx["ticket_actual"]

        advertencia = None

        # Si la meta es menor al ticket actual, no tiene sentido
        if ticket_objetivo <= t:
            advertencia = (
                f"La meta ${ticket_objetivo:,.0f} es menor o igual al ticket actual "
                f"(${t:,.2f}). Se ajustó automáticamente a la meta conservadora."
            )
            ticket_objetivo = round(ctx["p75"], 2)

        # Si la meta supera el P95, es poco realista
        elif ticket_objetivo > ctx["p95"]:
            advertencia = (
                f"La meta ${ticket_objetivo:,.0f} supera el percentil 95 de tus pedidos "
                f"(${ctx['p95']:,.0f}). Es muy agresiva — considera empezar con "
                f"${round(ctx['p90'], 0):,.0f} y escalar."
            )

        self.meta_objetivo = ticket_objetivo

        return {
            "meta_aceptada":  True,
            "ticket_actual":  round(t, 2),
            "ticket_objetivo":round(ticket_objetivo, 2),
            "incremento_pct": round((ticket_objetivo / t - 1) * 100, 1),
            "advertencia":    advertencia,
        }

    # ── 3. Generar plan con mini-goals ────────────────────

    def generar_plan(self) -> dict:
        """
        Desglosa la meta en 4 mini-goals (25/50/75/100%) con
        acciones concretas y métricas de seguimiento para cada etapa.

        Requiere haber llamado definir_meta() primero.

        Retorna
        -------
        {
          meta_objetivo,
          ticket_actual,
          mini_goals: [
            {
              etapa, pct, ticket_meta_etapa,
              incremento_desde_actual,
              acciones: [{accion, impacto}],
              como_medir
            }
          ]
        }
        """
        if self.meta_objetivo is None:
            raise RuntimeError("Llama a definir_meta() antes de generar_plan().")

        ctx  = self.contexto
        t    = ctx["ticket_actual"]
        meta = self.meta_objetivo
        gap  = meta - t

        mini_goals = []
        for pct, label in zip(HITOS, HITOS_LABELS):
            ticket_etapa       = round(t + gap * pct, 2)
            incremento_etapa   = round(ticket_etapa - t, 2)
            incremento_etapa_p = round((ticket_etapa / t - 1) * 100, 1)

            acciones = self._seleccionar_acciones(str(int(pct * 100)), ctx, meta)

            mini_goals.append({
                "etapa":                label,
                "pct_avance":          int(pct * 100),
                "ticket_meta_etapa":   ticket_etapa,
                "incremento_vs_actual":incremento_etapa,
                "incremento_pct":      incremento_etapa_p,
                "acciones":            acciones,
                "como_medir": (
                    f"Calcula el promedio de los últimos 200 pedidos. "
                    f"Si supera ${ticket_etapa:,.0f}, esta etapa está completa."
                ),
            })

        self._plan = {
            "ticket_actual":  round(t, 2),
            "meta_objetivo":  round(meta, 2),
            "incremento_total_pct": round((meta / t - 1) * 100, 1),
            "mini_goals":     mini_goals,
        }
        return self._plan

    # ── 4. Evaluar avance ─────────────────────────────────

    def evaluar_avance(self, pedidos_recientes: pd.DataFrame, ventana: int = 200) -> dict:
        """
        Evalúa el avance hacia la meta con pedidos recientes.

        Parámetros
        ----------
        pedidos_recientes : DataFrame con columna 'Total' de pedidos entregados
        ventana           : cuántos pedidos usar para calcular el ticket actual

        Retorna
        -------
        {
          ticket_ventana_actual,
          meta_objetivo,
          avance_pct,
          etapa_actual,
          siguiente_etapa,
          mensaje
        }
        """
        if self.meta_objetivo is None:
            raise RuntimeError("Llama a definir_meta() antes de evaluar_avance().")

        entregados = pedidos_recientes[
            pedidos_recientes["status_final"] == "Entregado"
        ].tail(ventana)

        if len(entregados) == 0:
            return {"error": "No hay pedidos entregados en los datos proporcionados."}

        ticket_ventana = entregados["Total"].mean()
        t_base         = self.contexto["ticket_actual"]
        meta           = self.meta_objetivo
        gap_total      = meta - t_base
        gap_actual     = ticket_ventana - t_base

        avance_pct = max(0, min(100, round(gap_actual / gap_total * 100, 1))) if gap_total > 0 else 0

        # Determinar en qué etapa está
        etapa_actual   = None
        siguiente      = None
        for i, (pct, label) in enumerate(zip(HITOS, HITOS_LABELS)):
            ticket_hito = t_base + gap_total * pct
            if ticket_ventana >= ticket_hito:
                etapa_actual = label
            else:
                if siguiente is None:
                    siguiente = {
                        "etapa":        label,
                        "ticket_meta":  round(ticket_hito, 2),
                        "faltan":       round(ticket_hito - ticket_ventana, 2),
                    }
                    break

        if avance_pct >= 100:
            mensaje = f"✅ ¡Meta alcanzada! Ticket actual ${ticket_ventana:,.2f} supera el objetivo ${meta:,.2f}."
        elif avance_pct >= 75:
            mensaje = f"Muy cerca — llevas {avance_pct}% del camino. Te faltan ${siguiente['faltan']:,.2f} por pedido para completar la meta."
        elif avance_pct >= 50:
            mensaje = f"A mitad del camino ({avance_pct}%). El ticket está en ${ticket_ventana:,.2f} — sigue con las acciones de la etapa 50%."
        elif avance_pct >= 25:
            mensaje = f"Buen inicio ({avance_pct}%). Enfócate en las acciones de la etapa 50% para acelerar."
        else:
            mensaje = f"Recién empezando ({avance_pct}%). Prioriza las acciones de la etapa 25% antes de avanzar."

        return {
            "ticket_ventana_actual": round(ticket_ventana, 2),
            "meta_objetivo":         round(meta, 2),
            "avance_pct":            avance_pct,
            "etapa_completada":      etapa_actual,
            "siguiente_etapa":       siguiente,
            "pedidos_evaluados":     len(entregados),
            "mensaje":               mensaje,
        }

    # ── Privados ──────────────────────────────────────────

    def _calcular_contexto(self):
        """Calcula todas las métricas base del negocio."""
        ent = self._entregados

        # Ticket stats
        ticket_actual  = ent["Total"].mean()
        ticket_mediana = ent["Total"].median()
        p75  = ent["Total"].quantile(0.75)
        p90  = ent["Total"].quantile(0.90)
        p95  = ent["Total"].quantile(0.95)

        # Tendencia: primeros vs últimos 2000 pedidos
        n          = min(2000, len(ent) // 4)
        primeros   = ent.head(n)["Total"].mean()
        ultimos    = ent.tail(n)["Total"].mean()
        tend_pct   = (ultimos - primeros) / primeros * 100

        # CEDIS
        cedis_stats = (
            ent.groupby("cedis")["Total"]
            .agg(["mean", "count"])
            .reset_index()
        )
        cedis_stats.columns = ["cedis", "ticket_prom", "pedidos"]
        cedis_stats = cedis_stats[cedis_stats["pedidos"] >= 50]  # solo CEDIS con volumen

        mejor_cedis_row = cedis_stats.sort_values("ticket_prom", ascending=False).iloc[0]
        peor_cedis_row  = cedis_stats.sort_values("ticket_prom").iloc[0]

        # Pedidos pequeños
        pct_pequenos = (ent["Total"] < ticket_mediana).mean() * 100

        # Sustituciones automatizables
        n_automatizables = 0
        producto_critico = "Coca-Cola"
        n_sustitutos     = 35
        if self._resultados is not None:
            from modules.sustituciones import AnalizadorSustituciones
            sust = AnalizadorSustituciones(self._resultados)
            n_automatizables = len(sust.pares_alta_confianza(min_confianza=80, min_ocurrencias=5))
            criticos = sust.productos_criticos(top_n=1)
            if criticos:
                producto_critico = criticos[0]["producto"]
                n_sustitutos     = criticos[0]["n_sustitutos_distintos"]

        self.ticket_actual  = round(ticket_actual, 2)
        self.ticket_mediana = round(ticket_mediana, 2)

        self.contexto = {
            "ticket_actual":       ticket_actual,
            "ticket_mediana":      ticket_mediana,
            "p75":                 p75,
            "p90":                 p90,
            "p95":                 p95,
            "tendencia_pct":       tend_pct,
            "mejor_cedis":         str(mejor_cedis_row["cedis"]),
            "ticket_mejor_cedis":  mejor_cedis_row["ticket_prom"],
            "peor_cedis":          str(peor_cedis_row["cedis"]),
            "ticket_peor_cedis":   peor_cedis_row["ticket_prom"],
            "brecha_cedis":        mejor_cedis_row["ticket_prom"] - peor_cedis_row["ticket_prom"],
            "pct_pequenos":        pct_pequenos,
            "n_automatizables":    n_automatizables,
            "producto_critico":    producto_critico,
            "n_sustitutos":        n_sustitutos,
        }

    def _interpretar_tendencia(self, pct: float) -> str:
        if pct >= 5:
            return f"El ticket promedio creció {pct:.1f}% en los pedidos más recientes — tendencia positiva."
        elif pct >= 0:
            return f"El ticket promedio está estable (+{pct:.1f}%) — hay margen para crecer."
        else:
            return f"El ticket promedio bajó {abs(pct):.1f}% en los pedidos recientes — atención necesaria."

    def _seleccionar_acciones(self, etapa: str, ctx: dict, meta: float) -> list:
        """Rellena las plantillas de acciones con datos reales del negocio."""
        plantillas = BANCO_ACCIONES.get(etapa, [])
        acciones   = []

        for p in plantillas:
            try:
                desc = p["accion"].format(
                    n_automatizables     = ctx["n_automatizables"],
                    producto_critico     = ctx["producto_critico"],
                    n_sustitutos         = ctx["n_sustitutos"],
                    mejor_cedis          = ctx["mejor_cedis"],
                    ticket_mejor_cedis   = ctx["ticket_mejor_cedis"],
                    brecha               = (ctx["ticket_mejor_cedis"] / ctx["ticket_actual"] - 1) * 100,
                    peor_cedis           = ctx["peor_cedis"],
                    ticket_peor_cedis    = ctx["ticket_peor_cedis"],
                    brecha_cedis         = ctx["brecha_cedis"],
                    umbral_combo         = round(ctx["ticket_mediana"] * 1.3, -2),
                    rango_bajo           = round(ctx["ticket_mediana"] * 0.5, -2),
                    rango_alto           = round(ctx["ticket_mediana"], -2),
                    meta_intermedia      = round(ctx["ticket_actual"] + (meta - ctx["ticket_actual"]) * 0.5, -2),
                    pct_pequenos         = ctx["pct_pequenos"],
                    mediana              = ctx["ticket_mediana"],
                    meta                 = meta,
                    siguiente_meta       = round(meta * 1.15, -2),
                )
                impacto = p["impacto"].format(
                    n_automatizables     = ctx["n_automatizables"],
                    mediana              = ctx["ticket_mediana"],
                    pct_pequenos         = ctx["pct_pequenos"],
                )
                acciones.append({"accion": desc, "impacto": impacto})
            except KeyError:
                acciones.append({"accion": p["accion"], "impacto": p["impacto"]})

        return acciones
