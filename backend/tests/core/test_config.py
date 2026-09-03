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


def test_simulation_data_is_disabled_by_default():
    settings = Settings(
        database_url=DEVELOPMENT_DATABASE_URL,
        mapbox_directions_access_token=None,
    )

    assert settings.enable_simulation_data is False
    assert settings.enable_simulation_analysis is False
    assert settings.mapbox_directions_access_token is None
    assert settings.usgs_lookback_days == 3650


def test_settings_reject_non_positive_usgs_lookback():
    with pytest.raises(ValidationError, match="USGS_LOOKBACK_DAYS"):
        Settings(database_url=DEVELOPMENT_DATABASE_URL, usgs_lookback_days=0)


def test_production_rejects_enabled_simulation_data():
    with pytest.raises(ValidationError, match="must not enable simulation data"):
        Settings(
            database_url=PRODUCTION_DATABASE_URL,
            environment="production",
            enable_simulation_data=True,
        )


def test_production_rejects_enabled_simulation_analysis():
    with pytest.raises(ValidationError, match="must not enable simulation analysis"):
        Settings(
            database_url=PRODUCTION_DATABASE_URL,
            environment="production",
            enable_simulation_analysis=True,
        )


def test_mapbox_directions_token_is_secret():
    settings = Settings(
        database_url=DEVELOPMENT_DATABASE_URL,
        mapbox_directions_access_token="sensitive-token",
    )

    assert "sensitive-token" not in repr(settings)
    assert settings.mapbox_directions_access_token.get_secret_value() == (
        "sensitive-token"
    )


@pytest.mark.parametrize(
    ("username", "password"),
    [
        ("safemyanmar_dev", "strong-production-password"),
        ("production_user", "safemyanmar_dev_password"),
    ],
)
def test_production_settings_reject_known_compose_development_credentials(
    username, password
):
    database_url = (
        f"postgresql+psycopg://{username}:{password}@"
        "db.internal.example/safemyanmar?sslmode=require"
    )

    with pytest.raises(ValidationError) as caught:
        Settings(database_url=database_url, environment="production")

    message = str(caught.value)
    assert "Production DATABASE_URL" in message
    assert database_url not in message
    assert username not in message
    assert password not in message
