from app.models.schemas import ModelOutputInput


PLACEHOLDER_RESPONSES = {
    "positivo": "El modelo detectó una clasificación positiva con {conf}% de confianza. El texto analizado presenta características favorables según los patrones aprendidos. Se recomienda tomar esto como una señal alentadora.",
    "negativo": "El modelo identificó una clasificación negativa con {conf}% de confianza. El texto analizado contiene elementos que el modelo asocia con patrones desfavorables. Se sugiere revisar el contenido con atención.",
    "neutro":   "El modelo clasificó el texto como neutro con {conf}% de confianza. No se detectaron señales claras positivas ni negativas. Puede ser útil obtener más contexto para una mejor interpretación.",
}

DEFAULT_RESPONSE = "El modelo arrojó la clasificación '{label}' con {conf}% de confianza. Esta es una interpretación placeholder; la interpretación real estará disponible cuando Gemini esté habilitado."


def get_placeholder_interpretation(data: ModelOutputInput) -> str:
    template = PLACEHOLDER_RESPONSES.get(data.label.lower(), DEFAULT_RESPONSE)
    return template.format(
        conf=f"{data.confidence * 100:.1f}",
        label=data.label
    )