import argparse
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


def create_server(host: str, port: int, fixture_path: Path) -> ThreadingHTTPServer:
    payload = fixture_path.read_bytes()

    class FixtureServer(ThreadingHTTPServer):
        failure_mode = False

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            if self.path != "/feed":
                self.send_error(HTTPStatus.NOT_FOUND)
                return
            if self.server.failure_mode:
                self.send_error(HTTPStatus.SERVICE_UNAVAILABLE)
                return
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", "application/geo+json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def do_POST(self) -> None:
            if self.path == "/control/fail":
                self.server.failure_mode = True
            elif self.path == "/control/ok":
                self.server.failure_mode = False
            else:
                self.send_error(HTTPStatus.NOT_FOUND)
                return
            self.send_response(HTTPStatus.NO_CONTENT)
            self.end_headers()

        def log_message(self, _format: str, *args: object) -> None:
            return

    return FixtureServer((host, port), Handler)


def main() -> None:
    parser = argparse.ArgumentParser(description="Test-only USGS fixture server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8001)
    parser.add_argument(
        "--fixture",
        type=Path,
        default=Path(__file__).with_name("usgs_integration_feed.json"),
    )
    args = parser.parse_args()
    server = create_server(args.host, args.port, args.fixture)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
