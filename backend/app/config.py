from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Env vars are LEDGERLY_* (e.g. LEDGERLY_DATABASE_URL); see docs/design-spec.md Section 4."""

    model_config = SettingsConfigDict(env_prefix="LEDGERLY_")

    database_url: str = "postgresql+asyncpg://ledgerly:ledgerly@localhost:5432/ledgerly"
    # Dev-only default. Real deployments set LEDGERLY_JWT_SECRET from Secret
    # Manager — HS256 wants at least 32 bytes or pyjwt itself warns about it.
    jwt_secret: str = "dev-secret-change-me-before-deploying-anywhere-real"
    jwt_access_token_minutes: int = 15


settings = Settings()
