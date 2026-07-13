import pytest
from pydantic import ValidationError

from app.core.config import Settings

DEVELOPMENT_DATABASE_URL = (
    "postgresql+psycopg://safemyanmar:development-password@localhost/safemyanmar"
)
PRODUCTION_DATABASE_URL = (
    "postgresql+psycopg://safemyanmar:strong-production-password@"
    "db.internal.example/safemyanmar?sslmode=require"
)


@pytest.mark.parametrize("environment", ["development", "test", "production"])
def test_settings_accept_supported_environments(environment):
    database_url = (
        PRODUCTION_DATABASE_URL
        if environment == "production"
        else DEVELOPMENT_DATABASE_URL
    )

    settings = Settings(database_url=database_url, environment=environment)

    assert settings.environment == environment


def test_settings_reject_unknown_environment():
    with pytest.raises(ValidationError, match="environment"):
        Settings(database_url=DEVELOPMENT_DATABASE_URL, environment="staging")


@pytest.mark.parametrize(
    "database_url",
    [
        "postgresql://user:password@localhost/safemyanmar",
        "postgresql+asyncpg://user:password@localhost/safemyanmar",
        "sqlite:///safemyanmar.sqlite",
        "not-a-database-url",
    ],
)
def test_settings_require_postgresql_psycopg(database_url):
    with pytest.raises(ValidationError, match=r"postgresql\+psycopg"):
        Settings(database_url=database_url)


@pytest.mark.parametrize(
    "database_url",
    [
        "postgresql+psycopg://user:password@localhost/db?sslmode=require",
        "postgresql+psycopg://user:password@127.0.0.1/db?sslmode=require",
        "postgresql+psycopg://user:password@[::1]/db?sslmode=require",
        "postgresql+psycopg://replace_me:password@db.example/db?sslmode=require",
        "postgresql+psycopg://user:replace_me@db.example/db?sslmode=require",
        "postgresql+psycopg://user:password@replace_me/db?sslmode=require",
        "postgresql+psycopg://user:password@db.example/replace_me?sslmode=require",
        "postgresql+psycopg://user:password@db.example/db",
        "postgresql+psycopg://user:password@db.example/db?sslmode=prefer",
    ],
)
def test_production_settings_reject_unsafe_database_urls(database_url):
    with pytest.raises(ValidationError, match="Production DATABASE_URL"):
        Settings(database_url=database_url, environment="production")


def test_production_settings_accept_remote_tls_database():
    settings = Settings(
        database_url=PRODUCTION_DATABASE_URL,
        environment="production",
    )

    assert settings.database_url == PRODUCTION_DATABASE_URL
