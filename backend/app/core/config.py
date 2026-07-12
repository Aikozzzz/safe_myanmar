from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str
    usgs_feed_url: str = (
        "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson"
    )
    provider_timeout_seconds: float = 10.0
    refresh_minimum_seconds: int = 60
    current_max_age_seconds: int = 300
