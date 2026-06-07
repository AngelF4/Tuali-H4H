from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    gemini_api_key: str
    rate_limit_per_minute: int = 10
    environment: str = "development"
    port: int = 8000

    class Config:
        env_file = ".env"


settings = Settings()