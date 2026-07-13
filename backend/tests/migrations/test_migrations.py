import os
import subprocess
import sys
from pathlib import Path

from alembic.config import Config
from sqlalchemy import (
    DateTime,
    Double,
    Integer,
    String,
    Text,
    create_engine,
    inspect,
    text,
)

from alembic import command

BACKEND_DIR = Path(__file__).resolve().parents[2]


def alembic_config(test_database_url: str) -> Config:
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", test_database_url)
    return config


def column_map(inspector, table_name: str) -> dict:
    return {column["name"]: column for column in inspector.get_columns(table_name)}


def normalized_check_expression(expression: str) -> str:
    return (
        expression.replace("'", "")
        .replace("::integer", "")
        .replace("::double precision", "")
        .replace(" ", "")
    )


def test_alembic_paths_are_cwd_independent(test_database_url, tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)

    config = alembic_config(test_database_url)

    assert Path(config.get_main_option("script_location")).resolve() == (
        BACKEND_DIR / "alembic"
    )
    assert Path(config.get_main_option("prepend_sys_path")).resolve() == BACKEND_DIR


def test_alembic_cli_uses_database_url_environment(test_database_url):
    environment = os.environ.copy()
    environment["DATABASE_URL"] = test_database_url

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "alembic",
            "-c",
            str(BACKEND_DIR / "alembic.ini"),
            "current",
        ],
        cwd=BACKEND_DIR.parent,
        env=environment,
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, "Alembic CLI must honor DATABASE_URL"


def test_upgrade_creates_required_schema(test_database_url):
    config = alembic_config(test_database_url)
    command.downgrade(config, "base")

    command.upgrade(config, "head")

    engine = create_engine(test_database_url)
    inspector = inspect(engine)
    assert {"earthquakes", "provider_sync"} <= set(inspector.get_table_names())

    earthquake_columns = column_map(inspector, "earthquakes")
    assert list(earthquake_columns) == [
        "id",
        "provider",
        "provider_event_id",
        "kind",
        "title",
        "place",
        "magnitude",
        "depth_km",
        "latitude",
        "longitude",
        "event_at",
        "provider_updated_at",
        "retrieved_at",
        "review_status",
        "source_url",
        "version",
        "created_at",
        "updated_at",
    ]
    expected_earthquake_strings = {
        "id": 255,
        "provider": 32,
        "provider_event_id": 255,
        "kind": 64,
        "title": 500,
        "place": 500,
        "review_status": 64,
    }
    for name, length in expected_earthquake_strings.items():
        assert isinstance(earthquake_columns[name]["type"], String)
        assert earthquake_columns[name]["type"].length == length
    for name in ("magnitude", "depth_km", "latitude", "longitude"):
        assert isinstance(earthquake_columns[name]["type"], Double)
    assert isinstance(earthquake_columns["source_url"]["type"], Text)
    assert isinstance(earthquake_columns["version"]["type"], Integer)
    for name in (
        "event_at",
        "provider_updated_at",
        "retrieved_at",
        "created_at",
        "updated_at",
    ):
        assert isinstance(earthquake_columns[name]["type"], DateTime)
        assert earthquake_columns[name]["type"].timezone is True
    assert {
        name: column["nullable"] for name, column in earthquake_columns.items()
    } == {name: name == "review_status" for name in earthquake_columns}
    assert {name: column["default"] for name, column in earthquake_columns.items()} == {
        **{
            name: None
            for name in earthquake_columns
            if name not in {"created_at", "updated_at"}
        },
        "created_at": "now()",
        "updated_at": "now()",
    }

    provider_columns = column_map(inspector, "provider_sync")
    assert list(provider_columns) == [
        "provider",
        "last_attempt_at",
        "last_successful_refresh_at",
        "last_error_code",
        "updated_at",
    ]
    assert isinstance(provider_columns["provider"]["type"], String)
    assert provider_columns["provider"]["type"].length == 32
    assert isinstance(provider_columns["last_error_code"]["type"], String)
    assert provider_columns["last_error_code"]["type"].length == 64
    for name in ("last_attempt_at", "last_successful_refresh_at", "updated_at"):
        assert isinstance(provider_columns[name]["type"], DateTime)
        assert provider_columns[name]["type"].timezone is True
    assert {name: column["nullable"] for name, column in provider_columns.items()} == {
        "provider": False,
        "last_attempt_at": False,
        "last_successful_refresh_at": True,
        "last_error_code": True,
        "updated_at": False,
    }
    assert {name: column["default"] for name, column in provider_columns.items()} == {
        "provider": None,
        "last_attempt_at": None,
        "last_successful_refresh_at": None,
        "last_error_code": None,
        "updated_at": "now()",
    }

    assert {
        constraint["name"]: constraint["column_names"]
        for constraint in inspector.get_unique_constraints("earthquakes")
    } == {"uq_earthquakes_provider_event": ["provider", "provider_event_id"]}
    assert {
        constraint["name"]: normalized_check_expression(constraint["sqltext"])
        for constraint in inspector.get_check_constraints("earthquakes")
    } == {
        "ck_earthquakes_latitude": "latitude>=-90ANDlatitude<=90",
        "ck_earthquakes_longitude": "longitude>=-180ANDlongitude<=180",
        "ck_earthquakes_version_positive": "version>0",
    }
    assert {
        index["name"]: (index["column_names"], index["unique"])
        for index in inspector.get_indexes("earthquakes")
        if index["name"].startswith("ix_")
    } == {
        "ix_earthquakes_event_at": (["event_at"], False),
        "ix_earthquakes_provider_updated_at": (["provider_updated_at"], False),
    }
    engine.dispose()


def test_downgrade_removes_tables_and_reupgrade_succeeds(test_database_url):
    config = alembic_config(test_database_url)
    command.upgrade(config, "head")

    command.downgrade(config, "base")

    engine = create_engine(test_database_url)
    assert "earthquakes" not in inspect(engine).get_table_names()
    assert "provider_sync" not in inspect(engine).get_table_names()
    with engine.connect() as connection:
        assert (
            connection.execute(
                text("SELECT to_regprocedure('set_updated_at()')")
            ).scalar_one()
            is None
        )
    engine.dispose()

    command.upgrade(config, "head")
    engine = create_engine(test_database_url)
    assert {"earthquakes", "provider_sync"} <= set(inspect(engine).get_table_names())
    engine.dispose()
