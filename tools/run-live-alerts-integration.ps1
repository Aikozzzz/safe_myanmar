[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,
    [string]$FlutterBin = "C:\Users\USER\develop\flutter\bin"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root "backend\.venv\Scripts\python.exe"
$databaseUrl = "postgresql+psycopg://safemyanmar_test:safemyanmar_test_password@localhost:5433/safemyanmar_test"
$provider = $null
$api = $null
$env:PATH = "$FlutterBin;$env:PATH"

function Wait-ForEndpoint {
    param([string]$Url)
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 1
            if ($response.StatusCode -eq 200) { return }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    throw "Endpoint $Url did not become ready within 15 seconds."
}

try {
    & docker compose --profile integration up -d integration-db
    if ($LASTEXITCODE -ne 0) { throw "Could not start integration database." }

    $env:DATABASE_URL = $databaseUrl
    $migrationSucceeded = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        & $python -m alembic -c (Join-Path $root "backend\alembic.ini") upgrade head
        if ($LASTEXITCODE -eq 0) {
            $migrationSucceeded = $true
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $migrationSucceeded) { throw "Could not migrate integration database." }

    $provider = Start-Process -FilePath $python -WorkingDirectory $root -PassThru -ArgumentList @(
        "backend\tests\fixtures\usgs_integration_server.py",
        "--host", "127.0.0.1",
        "--port", "8001"
    )
    Wait-ForEndpoint "http://127.0.0.1:8001/feed"

    $env:USGS_FEED_URL = "http://127.0.0.1:8001/feed"
    $api = Start-Process -FilePath $python -WorkingDirectory (Join-Path $root "backend") -PassThru -ArgumentList @(
        "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"
    )
    Wait-ForEndpoint "http://127.0.0.1:8000/health/ready"

    Push-Location (Join-Path $root "mobile")
    try {
        & flutter test integration_test/live_alerts_test.dart -d $DeviceId `
            --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
            --dart-define=INTEGRATION_PHASE=online
        if ($LASTEXITCODE -ne 0) { throw "Online integration phase failed." }

        Stop-Process -Id $api.Id
        Wait-Process -Id $api.Id
        $api = $null

        & flutter test integration_test/live_alerts_test.dart -d $DeviceId `
            --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
            --dart-define=INTEGRATION_PHASE=offline
        if ($LASTEXITCODE -ne 0) { throw "Offline integration phase failed." }
    } finally {
        Pop-Location
    }
} finally {
    if ($null -ne $api -and -not $api.HasExited) { Stop-Process -Id $api.Id }
    if ($null -ne $provider -and -not $provider.HasExited) {
        Stop-Process -Id $provider.Id
    }

    $adb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
    if (Test-Path -LiteralPath $adb) {
        & $adb -s $DeviceId shell pm clear org.safemyanmar.mobile | Out-Null
    }
    & docker compose --profile integration rm -f -s integration-db | Out-Null
}
