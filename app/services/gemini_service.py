from google import genai
from google.genai import types
from app.core.config import settings

_client = genai.Client(api_key=settings.gemini_api_key)

_CONFIG = types.GenerateContentConfig(
    max_output_tokens=400,
    temperature=0.4,
)

# ── Prompts por módulo ────────────────────────────────────

_PROMPTS = {
    "resumen_general": """Eres un asesor de negocios experto. Analiza estos datos de un negocio de distribución de bebidas en México y da un resumen ejecutivo breve (máximo 4 oraciones). Sé directo, usa números concretos y termina con la acción más urgente.

Datos:
{datos}""",

    "reporte_ventas": """Eres un analista de ventas. Interpreta estos KPIs de ventas en lenguaje claro para el dueño del negocio (no para un analista). Máximo 3 oraciones. Destaca lo más importante y menciona si algo necesita atención.

Datos de ventas:
{datos}""",

    "metas": """Eres un coach de negocios. Explica estas 3 opciones de meta al dueño del negocio de forma clara y motivadora. Máximo 4 oraciones en total. Recomienda cuál elegir y por qué.

Datos:
{datos}""",

    "estrategias": """Eres un consultor de negocios especializado en distribución. Basándote en estos datos reales del negocio, sugiere 3 estrategias concretas y accionables (promociones, campañas, cambios operativos) para aumentar el ticket promedio. Cada estrategia en una oración. Usa los números reales.

Datos del negocio:
{datos}""",

    "prediccion": """Eres un analista financiero. Interpreta esta predicción de ventas para el dueño del negocio. Máximo 3 oraciones. Menciona el margen de error del modelo y qué significa en términos prácticos.

Datos:
{datos}""",

    "inventario": """Eres un experto en cadena de suministro. Basándote en estos datos, da recomendaciones concretas de inventario. Prioriza los productos más críticos. Máximo 4 oraciones.

Datos:
{datos}""",

    "anomalias": """Eres un analista de datos. Describe brevemente qué representan estas anomalías en los datos de ventas y si requieren atención inmediata. Máximo 3 oraciones.

Datos:
{datos}""",

    "sustituciones": """Eres un experto en operaciones de distribución. Interpreta estos patrones de sustitución de productos. Identifica oportunidades de automatización y riesgos. Máximo 4 oraciones.

Datos:
{datos}""",

    "productos_problematicos": """Eres un analista de operaciones. Explica qué significan estas tasas de sustitución y qué riesgo representan para el negocio. Máximo 3 oraciones. Menciona el producto más crítico.

Datos:
{datos}""",

    "meta_personalizada": """Eres un coach de negocios. El dueño quiere establecer una meta de ticket promedio de ${meta_objetivo:,.0f}. Su ticket actual es ${ticket_actual:,.2f}. Evalúa si es realista, qué significa ese incremento y cuál sería la primera acción concreta para lograrlo. Máximo 4 oraciones.

Contexto adicional:
{datos}""",
}


async def interpretar(modulo: str, datos: dict, extra: dict = None) -> str:
    """
    Genera una interpretación en lenguaje natural para el módulo dado.

    Parámetros
    ----------
    modulo : clave del prompt (ver _PROMPTS)
    datos  : dict con los datos a interpretar
    extra  : parámetros adicionales para el prompt (ej. meta_objetivo)
    """
    if modulo not in _PROMPTS:
        raise ValueError(f"Módulo '{modulo}' no reconocido. Opciones: {list(_PROMPTS.keys())}")

    import json
    datos_str = json.dumps(datos, ensure_ascii=False, indent=2)

    fmt_kwargs = {"datos": datos_str}
    if extra:
        fmt_kwargs.update(extra)

    try:
        prompt = _PROMPTS[modulo].format(**fmt_kwargs)
    except KeyError as e:
        raise ValueError(f"Falta el parámetro {e} para el módulo '{modulo}'")

    response = _client.models.generate_content(
        model="gemini-3.1-flash-lite",
        contents=prompt,
        config=_CONFIG,
    )
    return response.text.strip()