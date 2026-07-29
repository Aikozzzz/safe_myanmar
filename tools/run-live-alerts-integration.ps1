[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,
    [string]$ApiBaseUrl,
    [string]$FlutterBin = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root "backend\.venv\Scripts\python.exe"
$databaseUrl = "postgresql+psycopg://safemyanmar_test:safemyanmar_test_password@localhost:5433/safemyanmar_test?connect_timeout=2"
$provider = $null
$api = $null
$adb = $null
$devicePort = 8000
$reverseConfigured = $false
$locationPushed = $false
$runError = $null
$cleanupErrors = [System.Collections.Generic.List[string]]::new()

$originalPathExists = Test-Path Env:PATH
$originalPathValue = $env:PATH
$originalDatabaseUrlExists = Test-Path Env:DATABASE_URL
$originalDatabaseUrlValue = $env:DATABASE_URL
$originalUsgsFeedUrlExists = Test-Path Env:USGS_FEED_URL
$originalUsgsFeedUrlValue = $env:USGS_FEED_URL
$originalEnvironmentExists = Test-Path Env:ENVIRONMENT
$originalEnvironmentValue = $env:ENVIRONMENT
$originalCurrentMaxAgeSecondsExists = Test-Path Env:CURRENT_MAX_AGE_SECONDS
$originalCurrentMaxAgeSecondsValue = $env:CURRENT_MAX_AGE_SECONDS
$originalRefreshMinimumSecondsExists = Test-Path Env:REFRESH_MINIMUM_SECONDS
$originalRefreshMinimumSecondsValue = $env:REFRESH_MINIMUM_SECONDS
$originalProviderTimeoutSecondsExists = Test-Path Env:PROVIDER_TIMEOUT_SECONDS
$originalProviderTimeoutSecondsValue = $env:PROVIDER_TIMEOUT_SECONDS

function Restore-EnvironmentVariable {
    param(
        [string]$Name,
        [bool]$Existed,
        [AllowNull()]
        [string]$Value
    )

    if ($Existed) {
        [Environment]::SetEnvironmentVariable($Name, $Value, "Process")
    } else {
        [Environment]::SetEnvironmentVariable($Name, $null, "Process")
    }
}

function Invoke-NativeCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [int]$TimeoutMilliseconds = 10000
    )

    $identifier = [Guid]::NewGuid().ToString("N")
    $standardOutputPath = Join-Path ([IO.Path]::GetTempPath()) "safemyanmar-$identifier.out"
    $standardErrorPath = Join-Path ([IO.Path]::GetTempPath()) "safemyanmar-$identifier.err"
    $process = $null
    try {
        $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru -NoNewWindow `
            -RedirectStandardOutput $standardOutputPath -RedirectStandardError $standardErrorPath
        $null = $process.Handle
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            try { $process.Kill() } catch { }
            $process.WaitForExit(2000) | Out-Null
            throw "Native command timed out."
        }

        return [PSCustomObject]@{
            ExitCode = $process.ExitCode
            StdOut = [IO.File]::ReadAllText($standardOutputPath)
            StdErr = [IO.File]::ReadAllText($standardErrorPath)
        }
    } finally {
        if ($null -ne $process) { $process.Dispose() }
        Remove-Item -LiteralPath $standardOutputPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $standardErrorPath -Force -ErrorAction SilentlyContinue
    }
}

function Wait-ForEndpoint {
    param(
        [string]$Url,
        [int]$TimeoutSeconds = 15
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 1
            if ($response.StatusCode -eq 200) { return }
        } catch {
            Start-Sleep -Milliseconds 250
        }
    } while ([DateTime]::UtcNow -lt $deadline)

    throw "A required local endpoint did not become ready within $TimeoutSeconds seconds."
}

function Stop-ChildProcess {
    param(
        [AllowNull()]
        [System.Diagnostics.Process]$Process,
        [int]$TimeoutSeconds = 10
    )

    if ($null -eq $Process) { return }
    $Process.Refresh()
    if ($Process.HasExited) { return }

    Stop-Process -Id $Process.Id -ErrorAction SilentlyContinue
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 100
        $Process.Refresh()
    } while (-not $Process.HasExited -and [DateTime]::UtcNow -lt $deadline)

    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
        $Process.WaitForExit(2000) | Out-Null
    }
    $Process.Refresh()
    if (-not $Process.HasExited) {
        throw "A local integration process could not be stopped."
    }
}

try {
    if (-not (Test-Path -LiteralPath $python)) {
        throw "The backend virtual environment is missing."
    }
    if (-not [string]::IsNullOrWhiteSpace($FlutterBin)) {
        if (-not (Test-Path -LiteralPath $FlutterBin)) {
            throw "FlutterBin does not exist."
        }
        $env:PATH = "$FlutterBin;$env:PATH"
    }

    $env:ENVIRONMENT = "test"
    $env:CURRENT_MAX_AGE_SECONDS = "300"
    $env:REFRESH_MINIMUM_SECONDS = "60"
    $env:PROVIDER_TIMEOUT_SECONDS = "10.0"

    $adbCommand = Get-Command adb -ErrorAction SilentlyContinue
    if ($null -ne $adbCommand) {
        $adb = $adbCommand.Source
    } else {
        $sdkAdb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
        if (Test-Path -LiteralPath $sdkAdb) { $adb = $sdkAdb }
    }
    if ($null -eq $adb) { throw "adb is required for Android integration." }

    $deviceState = Invoke-NativeCommand -FilePath $adb -Arguments @("-s", $DeviceId, "get-state")
    if ($deviceState.ExitCode -ne 0 -or $deviceState.StdOut.Trim() -ne "device") {
        throw "The selected Android device is not ready."
    }
    $emulatorFlag = Invoke-NativeCommand -FilePath $adb -Arguments @("-s", $DeviceId, "shell", "getprop", "ro.kernel.qemu")
    if ($emulatorFlag.ExitCode -ne 0) { throw "Could not inspect the Android device." }
    $isEmulator = $emulatorFlag.StdOut.Trim() -eq "1"

    if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        $ApiBaseUrl = if ($isEmulator) {
            "http://10.0.2.2:8000"
        } else {
            "http://127.0.0.1:8000"
        }
    }

    if ($isEmulator) {
        if ($ApiBaseUrl -cne "http://10.0.2.2:8000") {
            throw "ApiBaseUrl must target the locally orchestrated emulator API."
        }
    } else {
        $localUrlPattern = '^http://(?:127\.0\.0\.1|localhost):(?<port>[0-9]{1,5})/?$'
        $localUrlMatch = [regex]::Match(
            $ApiBaseUrl,
            $localUrlPattern,
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        if (-not $localUrlMatch.Success) {
            throw "ApiBaseUrl must target the locally orchestrated physical-device API."
        }
        $devicePort = [int]$localUrlMatch.Groups["port"].Value
        if ($devicePort -lt 1 -or $devicePort -gt 65535) {
            throw "ApiBaseUrl contains an invalid port."
        }

        $reverseConfigured = $true
        $reverse = Invoke-NativeCommand -FilePath $adb -Arguments @("-s", $DeviceId, "reverse", "tcp:$devicePort", "tcp:8000")
        if ($reverse.ExitCode -ne 0) { throw "Could not configure adb reverse." }
    }

    $databaseStart = Invoke-NativeCommand -FilePath "docker" -Arguments @("compose", "--profile", "integration", "up", "-d", "--wait", "--wait-timeout", "30", "integration-db") -TimeoutMilliseconds 60000
    if ($databaseStart.ExitCode -ne 0) { throw "Could not start integration database." }

    $env:DATABASE_URL = $databaseUrl
    $migrationSucceeded = $false
    $migrationDeadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        & $python -m alembic -c (Join-Path $root "backend\alembic.ini") upgrade head
        if ($LASTEXITCODE -eq 0) {
            $migrationSucceeded = $true
            break
        }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $migrationDeadline)
    if (-not $migrationSucceeded) { throw "Could not migrate integration database." }

    $provider = Start-Process -FilePath $python -WorkingDirectory $root -PassThru -ArgumentList @(
        "backend\tests\fixtures\usgs_integration_server.py",
        "--host", "127.0.0.1",
        "--port", "8001"
    )
    Wait-ForEndpoint "http://127.0.0.1:8001/feed"

    $env:USGS_FEED_URL = "http://127.0.0.1:8001/feed"
    $api = Start-Process -FilePath $python -WorkingDirectory (Join-Path $root "backend") -PassThru -ArgumentList @(
        "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"
    )
    Wait-ForEndpoint "http://127.0.0.1:8000/health/ready"

    Push-Location (Join-Path $root "mobile")
    $locationPushed = $true
    & flutter test integration_test/live_alerts_test.dart -d $DeviceId `
        --dart-define=API_BASE_URL=$ApiBaseUrl `
        --dart-define=INTEGRATION_PHASE=online
    if ($LASTEXITCODE -ne 0) { throw "Online integration phase failed." }

    Stop-ChildProcess -Process $api
    $api = $null

    & flutter test integration_test/live_alerts_test.dart -d $DeviceId `
        --dart-define=API_BASE_URL=$ApiBaseUrl `
        --dart-define=INTEGRATION_PHASE=offline
    if ($LASTEXITCODE -ne 0) { throw "Offline integration phase failed." }
} catch {
    $runError = $_
} finally {
    if ($locationPushed) {
        try { Pop-Location } catch { $cleanupErrors.Add("working directory") }
    }
    try { Stop-ChildProcess -Process $api } catch { $cleanupErrors.Add("API process") }
    try { Stop-ChildProcess -Process $provider } catch { $cleanupErrors.Add("provider process") }

    if ($null -ne $adb) {
        try {
            $clearResult = Invoke-NativeCommand -FilePath $adb -Arguments @("-s", $DeviceId, "shell", "pm", "clear", "org.safemyanmar.mobile")
            $clearOutput = $clearResult.StdOut.Trim()
            if ($clearResult.ExitCode -ne 0 -or $clearOutput -ne "Success") {
                $cleanupErrors.Add("Android application data")
            }
        } catch {
            $cleanupErrors.Add("Android application data")
        }
        if ($reverseConfigured) {
            try {
                $reverseRemoval = Invoke-NativeCommand -FilePath $adb -Arguments @("-s", $DeviceId, "reverse", "--remove", "tcp:$devicePort")
                if ($reverseRemoval.ExitCode -ne 0) { $cleanupErrors.Add("adb reverse") }
            } catch {
                $cleanupErrors.Add("adb reverse")
            }
        }
    }

    try {
        $databaseRemoval = Invoke-NativeCommand -FilePath "docker" -Arguments @("compose", "--profile", "integration", "rm", "-f", "-s", "integration-db") -TimeoutMilliseconds 30000
        if ($databaseRemoval.ExitCode -ne 0) { $cleanupErrors.Add("integration database") }
    } catch {
        $cleanupErrors.Add("integration database")
    }

    try {
        Restore-EnvironmentVariable "PATH" $originalPathExists $originalPathValue
    } catch { $cleanupErrors.Add("PATH") }
    try {
        Restore-EnvironmentVariable "DATABASE_URL" $originalDatabaseUrlExists $originalDatabaseUrlValue
    } catch { $cleanupErrors.Add("DATABASE_URL") }
    try {
        Restore-EnvironmentVariable "USGS_FEED_URL" $originalUsgsFeedUrlExists $originalUsgsFeedUrlValue
    } catch { $cleanupErrors.Add("USGS_FEED_URL") }
    try {
        Restore-EnvironmentVariable "ENVIRONMENT" $originalEnvironmentExists $originalEnvironmentValue
    } catch { $cleanupErrors.Add("ENVIRONMENT") }
    try {
        Restore-EnvironmentVariable "CURRENT_MAX_AGE_SECONDS" $originalCurrentMaxAgeSecondsExists $originalCurrentMaxAgeSecondsValue
    } catch { $cleanupErrors.Add("CURRENT_MAX_AGE_SECONDS") }
    try {
        Restore-EnvironmentVariable "REFRESH_MINIMUM_SECONDS" $originalRefreshMinimumSecondsExists $originalRefreshMinimumSecondsValue
    } catch { $cleanupErrors.Add("REFRESH_MINIMUM_SECONDS") }
    try {
        Restore-EnvironmentVariable "PROVIDER_TIMEOUT_SECONDS" $originalProviderTimeoutSecondsExists $originalProviderTimeoutSecondsValue
    } catch { $cleanupErrors.Add("PROVIDER_TIMEOUT_SECONDS") }
}

if ($null -ne $runError) {
    if ($cleanupErrors.Count -gt 0) {
        throw "$($runError.Exception.Message) Cleanup also failed: $($cleanupErrors -join ', ')."
    }
    throw $runError
}
if ($cleanupErrors.Count -gt 0) {
    throw "Integration cleanup failed: $($cleanupErrors -join ', ')."
}
