import os
import sys
import types as _types

from fastapi import APIRouter, Request, HTTPException
from app.core.config import settings
from app.core.limiter import limiter
from app.models.schemas import MetaPersonalizadaRequest, InterpretacionResponse, MetaPersonalizadaResponse
from app.services import data_service, gemini_service

# ── Imports de módulos propios ────────────────────────────
_MODULES_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "modules")
_DATA_DIR    = os.path.join(os.path.dirname(__file__), "..", "..", "data")

if _MODULES_DIR not in sys.path:
    sys.path.insert(0, _MODULES_DIR)

import sustituciones as _sust_mod
if "modules" not in sys.modules:
    sys.modules["modules"] = _types.ModuleType("modules")
sys.modules["modules.sustituciones"] = _sust_mod

from data_loader import cargar_datos
from metas import MotorMetas

# ── Router ────────────────────────────────────────────────
router = APIRouter(prefix="/api/v1", tags=["inteligencia comercial"])


# ── Health ────────────────────────────────────────────────

@router.get("/health")
async def health():
    return {"status": "ok", "environment": settings.environment}


# ── Helper ───────────────────────────────────────────────

async def _responder(request: Request, modulo: str, datos: dict, extra: dict = None):
    """Helper que llama a Gemini en production o devuelve datos crudos en development."""
    if settings.environment == "production":
        try:
            interpretacion = await gemini_service.interpretar(modulo, datos, extra)
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Error Gemini: {str(e)}")
    else:
        interpretacion = "[development] Datos calculados. Activa ENVIRONMENT=production para interpretación con Gemini."

    return InterpretacionResponse(modulo=modulo, interpretacion=interpretacion, datos=datos)


# ── Endpoints ─────────────────────────────────────────────

@router.get("/resumen", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def resumen_general(request: Request):
    """Resumen ejecutivo del estado del negocio."""
    reporte = data_service.get_reporte()
    datos = {
        "ticket_promedio":           reporte["ventas"]["kpis"]["ticket_promedio"],
        "tasa_entrega_pct":          reporte["ventas"]["kpis"]["tasa_entrega_pct"],
        "venta_total":               reporte["ventas"]["kpis"]["venta_total"],
        "total_pedidos":             reporte["ventas"]["kpis"]["total_pedidos"],
        "tasa_sustitucion_global":   reporte["tasa_sustitucion_global"],
        "producto_mas_critico":      reporte["productos_problematicos"][0]["producto"],
        "anomalias_detectadas":      len(reporte["anomalias"]),
        "tendencia_reciente_pct":    reporte["metas"]["tendencia_reciente_pct"],
        "nota_tendencia":            reporte["metas"]["nota_tendencia"],
        "prediccion_proximo_bloque": reporte["prediccion"]["bloques"][0],
    }
    return await _responder(request, "resumen_general", datos)


@router.get("/ventas", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def reporte_ventas(request: Request):
    """KPIs completos de ventas con interpretación."""
    reporte = data_service.get_reporte()
    datos = reporte["ventas"]
    return await _responder(request, "reporte_ventas", datos)


@router.get("/prediccion", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def prediccion_ventas(request: Request):
    """Predicción de ventas para los próximos bloques."""
    reporte = data_service.get_reporte()
    datos = reporte["prediccion"]
    return await _responder(request, "prediccion", datos)


@router.get("/metas", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def metas_sugeridas(request: Request):
    """Metas inteligentes sugeridas basadas en datos reales."""
    reporte = data_service.get_reporte()
    datos = reporte["metas"]
    return await _responder(request, "metas", datos)


@router.post("/metas/personalizada", response_model=MetaPersonalizadaResponse)
@limiter.limit("10/minute")
async def meta_personalizada(request: Request, body: MetaPersonalizadaRequest):
    """El usuario define su propia meta y recibe un plan + interpretación."""
    orders_mx, resultados_mx = cargar_datos(
        os.path.join(_DATA_DIR, "Orders.csv"),
        os.path.join(_DATA_DIR, "Resultados.csv"),
    )

    motor  = MotorMetas(orders_mx, resultados_mx)
    result = motor.definir_meta(body.ticket_objetivo)
    plan   = motor.generar_plan()

    datos_extra = {
        "plan_mini_goals": [
            {
                "etapa":       mg["etapa"],
                "ticket_meta": mg["ticket_meta_etapa"],
                "acciones":    [a["accion"] for a in mg["acciones"][:2]],
            }
            for mg in plan["mini_goals"]
        ]
    }

    if settings.environment == "production":
        try:
            interpretacion = await gemini_service.interpretar(
                "meta_personalizada",
                datos_extra,
                extra={
                    "meta_objetivo": result["ticket_objetivo"],
                    "ticket_actual": result["ticket_actual"],
                },
            )
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Error Gemini: {str(e)}")
    else:
        interpretacion = "[development] Meta calculada. Activa ENVIRONMENT=production para interpretación con Gemini."

    return MetaPersonalizadaResponse(
        ticket_actual   = result["ticket_actual"],
        ticket_objetivo = result["ticket_objetivo"],
        incremento_pct  = result["incremento_pct"],
        advertencia     = result["advertencia"],
        interpretacion  = interpretacion,
    )


@router.get("/estrategias", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def estrategias(request: Request):
    """Estrategias concretas: promociones, campañas, acciones operativas."""
    reporte = data_service.get_reporte()
    datos = {
        "ticket_promedio":        reporte["ventas"]["kpis"]["ticket_promedio"],
        "ticket_mediana":         reporte["ventas"]["kpis"]["ticket_mediana"],
        "tasa_entrega_pct":       reporte["ventas"]["kpis"]["tasa_entrega_pct"],
        "top_cedis":              reporte["ventas"]["cedis"][:3],
        "segmentacion":           reporte["ventas"]["segmentacion"],
        "tasa_sustitucion":       reporte["tasa_sustitucion_global"],
        "pares_automatizables":   reporte["optimizacion_sustituciones"]["total_cruzadas"],
        "meta_sugerida_moderada": reporte["metas"]["sugerencias"][1],
        "tendencia_pct":          reporte["metas"]["tendencia_reciente_pct"],
    }
    return await _responder(request, "estrategias", datos)


@router.get("/inventario", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def inventario(request: Request):
    """Recomendaciones de inventario basadas en agotamientos reales."""
    reporte = data_service.get_reporte()
    datos = reporte["inventario_recomendado"]
    return await _responder(request, "inventario", datos)


@router.get("/anomalias", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def anomalias(request: Request):
    """Detección de pedidos anómalos (outliers estadísticos)."""
    reporte = data_service.get_reporte()
    datos = {
        "total_anomalias":        len(reporte["anomalias"]),
        "pct_del_total":          round(len(reporte["anomalias"]) / reporte["ventas"]["kpis"]["total_pedidos"] * 100, 1),
        "ejemplos":               reporte["anomalias"][:5],
        "ticket_promedio_normal": reporte["ventas"]["kpis"]["ticket_promedio"],
    }
    return await _responder(request, "anomalias", datos)


@router.get("/sustituciones", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def sustituciones(request: Request):
    """Análisis completo de sustituciones y optimización."""
    reporte = data_service.get_reporte()
    datos = {
        "kpis":                    reporte["sustituciones"]["kpis"],
        "tasa_global_pct":         reporte["tasa_sustitucion_global"],
        "productos_problematicos": reporte["productos_problematicos"][:5],
        "optimizacion":            reporte["optimizacion_sustituciones"],
    }
    return await _responder(request, "sustituciones", datos)


@router.get("/productos-problematicos", response_model=InterpretacionResponse)
@limiter.limit("10/minute")
async def productos_problematicos(request: Request):
    """Productos con alta tasa de sustitución."""
    reporte = data_service.get_reporte()
    datos = {
        "productos":               reporte["productos_problematicos"],
        "tasa_sustitucion_global": reporte["tasa_sustitucion_global"],
        "total_sustituciones":     reporte["sustituciones"]["kpis"]["total_sustituciones"],
    }
    return await _responder(request, "productos_problematicos", datos)