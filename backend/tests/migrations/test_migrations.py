from alembic.config import Config
from sqlalchemy import create_engine, inspect

from alembic import command


def alembic_config(test_database_url: str) -> Config:
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", test_database_url)
    return config


def test_upgrade_creates_required_schema(test_database_url):
    config = alembic_config(test_database_url)
    command.downgrade(config, "base")

    command.upgrade(config, "head")

    engine = create_engine(test_database_url)
    inspector = inspect(engine)
    assert {"earthquakes", "provider_sync"} <= set(inspector.get_table_names())
    assert {
        constraint["name"]
        for constraint in inspector.get_unique_constraints("earthquakes")
    } == {"uq_earthquakes_provider_event"}
    assert {
        constraint["name"]
        for constraint in inspector.get_check_constraints("earthquakes")
    } == {
        "ck_earthquakes_latitude",
        "ck_earthquakes_longitude",
        "ck_earthquakes_version_positive",
    }
    assert {index["name"] for index in inspector.get_indexes("earthquakes")} >= {
        "ix_earthquakes_event_at",
        "ix_earthquakes_provider_updated_at",
    }
    engine.dispose()


def test_downgrade_removes_tables_and_reupgrade_succeeds(test_database_url):
    config = alembic_config(test_database_url)
    command.upgrade(config, "head")

    command.downgrade(config, "base")

    engine = create_engine(test_database_url)
    assert "earthquakes" not in inspect(engine).get_table_names()
    assert "provider_sync" not in inspect(engine).get_table_names()
    engine.dispose()

    command.upgrade(config, "head")
    engine = create_engine(test_database_url)
    assert {"earthquakes", "provider_sync"} <= set(inspect(engine).get_table_names())
    engine.dispose()
