from collections.abc import Callable
from datetime import UTC, datetime
from types import TracebackType

import httpx


class ProviderClientError(Exception):
    code: str

    def __init__(self, code: str) -> None:
        self.code = code
        super().__init__(code)


class UsgsClient:
    def __init__(
        self,
        feed_url: str,
        timeout_seconds: float = 10.0,
        http_client: httpx.Client | None = None,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self._feed_url = feed_url
        self._timeout_seconds = timeout_seconds
        self._owns_http_client = http_client is None
        self._http_client = http_client or httpx.Client()
        self._clock = clock or (lambda: datetime.now(UTC))

    def fetch(self) -> tuple[dict[str, object], datetime]:
        try:
            response = self._http_client.get(
                self._feed_url, timeout=self._timeout_seconds
            )
            response.raise_for_status()
        except httpx.TimeoutException as error:
            raise ProviderClientError("provider_timeout") from error
        except (httpx.RequestError, httpx.HTTPStatusError) as error:
            raise ProviderClientError("provider_unavailable") from error

        try:
            payload = response.json()
        except ValueError as error:
            raise ProviderClientError("invalid_provider_payload") from error
        if not isinstance(payload, dict):
            raise ProviderClientError("invalid_provider_payload")

        retrieved_at = self._clock()
        if retrieved_at.tzinfo is None or retrieved_at.utcoffset() is None:
            raise ProviderClientError("invalid_provider_payload")
        return payload, retrieved_at.astimezone(UTC)

    def close(self) -> None:
        if self._owns_http_client:
            self._http_client.close()

    def __enter__(self) -> "UsgsClient":
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        self.close()
