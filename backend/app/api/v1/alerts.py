from collections.abc import Callable, Iterator
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.errors import ApiError
from app.schemas.earthquakes import AlertItem, AlertListResponse
from app.services.earthquakes import EarthquakeService, LiveDataUnavailable

router = APIRouter(prefix="/alerts", tags=["alerts"])


def get_session(request: Request) -> Iterator[Session]:
    with request.app.state.session_factory() as session:
        yield session


def get_earthquake_service(request: Request) -> EarthquakeService:
    return request.app.state.earthquake_service


def get_clock() -> Callable[[], datetime]:
    return lambda: datetime.now(UTC)


@router.get("", response_model=AlertListResponse)
def list_alerts(
    session: Session = Depends(get_session),
    service: EarthquakeService = Depends(get_earthquake_service),
    clock: Callable[[], datetime] = Depends(get_clock),
) -> AlertListResponse:
    try:
        collection = service.list_alerts(session, clock())
    except LiveDataUnavailable as error:
        session.commit()
        raise ApiError(
            503,
            "live_data_unavailable",
            "Live earthquake data is currently unavailable.",
        ) from error
    except Exception:
        session.rollback()
        raise

    try:
        response = AlertListResponse(
            items=[AlertItem.model_validate(item) for item in collection.items],
            data_status=collection.data_status,
            last_successful_refresh_at=collection.last_successful_refresh_at,
        )
        session.commit()
        return response
    except Exception:
        session.rollback()
        raise


@router.get("/{alert_id}", response_model=AlertItem)
def get_alert(
    alert_id: str,
    session: Session = Depends(get_session),
    service: EarthquakeService = Depends(get_earthquake_service),
) -> AlertItem:
    try:
        item = service.get_alert(session, alert_id)
        if item is None:
            raise ApiError(
                404,
                "not_found",
                "Earthquake information was not found.",
            )
        response = AlertItem.model_validate(item)
    finally:
        session.rollback()
    return response
