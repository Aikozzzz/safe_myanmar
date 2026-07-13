from ipaddress import ip_address
from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError

_PLACEHOLDER_VALUES = {
    "change_me",
    "changeme",
    "example",
    "password",
    "placeholder",
    "replace_me",
    "safemyanmar_dev",
    "safemyanmar_dev_password",
    "user",
    "username",
}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
        hide_input_in_errors=True,
    )

    database_url: str
    environment: Literal["development", "test", "production"] = "development"
    usgs_feed_url: str = (
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
    )
    provider_timeout_seconds: float = 10.0
    refresh_minimum_seconds: int = 60
    current_max_age_seconds: int = 300

    @model_validator(mode="after")
    def validate_database_url(self) -> "Settings":
        try:
            url = make_url(self.database_url)
        except ArgumentError as error:
            raise ValueError("DATABASE_URL must use postgresql+psycopg.") from error

        if url.drivername != "postgresql+psycopg":
            raise ValueError("DATABASE_URL must use postgresql+psycopg.")
        if self.environment != "production":
            return self

        components = (url.username, url.password, url.host, url.database)
        if any(
            component is None
            or not component.strip()
            or component.casefold() in _PLACEHOLDER_VALUES
            for component in components
        ):
            raise ValueError(
                "Production DATABASE_URL must use non-placeholder connection values."
            )

        host = url.host.casefold()
        is_loopback = host == "localhost" or host.endswith(".localhost")
        try:
            address = ip_address(host)
        except ValueError:
            pass
        else:
            is_loopback = address.is_loopback or address.is_unspecified
        if is_loopback:
            raise ValueError("Production DATABASE_URL must use a non-loopback host.")
        if url.query.get("sslmode") != "require":
            raise ValueError("Production DATABASE_URL must set sslmode=require.")
        return self
