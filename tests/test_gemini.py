import os
import sys
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY or API_KEY == "tu_api_key_aqui":
    print("❌ ERROR: No hay una API key válida en tu .env")
    sys.exit(1)

print("🔑 API key encontrada. Conectando con Gemini...\n")

try:
    client = genai.Client(api_key=API_KEY)

    response = client.models.generate_content(
        model="gemini-3.1-flash-lite",
        contents='Responde solo con: "Conexión exitosa con Gemini ✅"',
        config=types.GenerateContentConfig(
            max_output_tokens=20,
            temperature=0,
        ),
    )

    print(f"Respuesta de Gemini: {response.text.strip()}")
    print("\n✅ Todo listo. Gemini está funcionando correctamente.")

except Exception as e:
    print(f"❌ Error al conectar con Gemini: {e}")
    sys.exit(1)