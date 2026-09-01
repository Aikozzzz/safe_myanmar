[CmdletBinding()]
param(
    [string]$DeviceId = "",
    [string]$HostAddress = "",
    [ValidateRange(1, 65535)]
    [int]$Port = 8000,
    [string]$FlutterBin = "",
    [string]$MapboxPublicAccessToken = "",
    [switch]$EnableSimulationData,
    [switch]$SkipDatabase,
    [switch]$SkipMigration
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"
$mobile = Join-Path $root "mobile"
$python = Join-Path $backend ".venv\Scripts\python.exe"
$adb = $null
$flutter = $null
$api = $null
$stdoutPath = $null
$stderrPath = $null
$failure = $null

function Resolve-Adb {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $sdkAdb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
    if (Test-Path -LiteralPath $sdkAdb) {
        return $sdkAdb
    }

    throw "adb was not found. Add Android SDK platform-tools to PATH."
}

function Resolve-Flutter {
    param([string]$ConfiguredPath)

    if (-not [string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        if (-not (Test-Path -LiteralPath $ConfiguredPath)) {
            throw "FlutterBin does not exist: $ConfiguredPath"
        }
        if ((Get-Item -LiteralPath $ConfiguredPath).PSIsContainer) {
            $candidate = Join-Path $ConfiguredPath "flutter.bat"
        } else {
            $candidate = $ConfiguredPath
        }
        if (-not (Test-Path -LiteralPath $candidate)) {
            throw "Flutter executable was not found: $candidate"
        }
        return $candidate
    }

    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "flutter was not found. Add Flutter to PATH or pass -FlutterBin."
    }
    return $command.Source
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        # Docker and Python may write normal progress messages to stderr.
        $ErrorActionPreference = "Continue"
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        $details = ($output | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($details)) {
            throw $FailureMessage
        }
        throw "$FailureMessage $details"
    }
}

function Test-PrivateIpv4 {
    param([Parameter(Mandatory = $true)][string]$Address)

    $parts = $Address.Split('.')
    if ($parts.Count -ne 4) {
        return $false
    }
    $values = @()
    foreach ($part in $parts) {
        $value = 0
        if (-not [int]::TryParse($part, [ref]$value) -or $value -lt 0 -or $value -gt 255) {
            return $false
        }
        $values += $value
    }
    return $values[0] -eq 10 -or
        ($values[0] -eq 172 -and $values[1] -ge 16 -and $values[1] -le 31) -or
        ($values[0] -eq 192 -and $values[1] -eq 168)
}

function Resolve-HostAddress {
    $addresses = @(
        Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            ForEach-Object { $_.IPAddress } |
            Where-Object { Test-PrivateIpv4 $_ } |
            Select-Object -Unique
    )
    if ($addresses.Count -eq 1) {
        return $addresses[0]
    }
    if ($addresses.Count -gt 1) {
        throw "Multiple private host addresses found: $($addresses -join ', '). Pass -HostAddress explicitly."
    }

    throw "No private host IPv4 address was found. Pass -HostAddress explicitly."
}

function Wait-ForApi {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 20
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    Start-Sleep -Milliseconds 250
    do {
        $Process.Refresh()
        if ($Process.HasExited) {
            $stderr = if ($null -ne $stderrPath -and (Test-Path -LiteralPath $stderrPath)) {
                Get-Content -LiteralPath $stderrPath -Raw
            } else {
                ""
            }
            throw ("The backend stopped before becoming ready. $stderr").Trim()
        }

        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 1
            if ($response.StatusCode -eq 200) {
                return
            }
        } catch {
            Start-Sleep -Milliseconds 250
        }
    } while ([DateTime]::UtcNow -lt $deadline)

    $stderr = if ($null -ne $stderrPath -and (Test-Path -LiteralPath $stderrPath)) {
        Get-Content -LiteralPath $stderrPath -Raw
    } else {
        ""
    }
    throw ("The backend did not become ready within $TimeoutSeconds seconds. $stderr").Trim()
}

function Stop-Api {
    param([AllowNull()][System.Diagnostics.Process]$Process)

    if ($null -eq $Process) {
        return
    }
    $Process.Refresh()
    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -ErrorAction SilentlyContinue
        $Process.WaitForExit(5000) | Out-Null
    }
}

try {
    if (-not (Test-Path -LiteralPath $python)) {
        throw "Backend virtual environment is missing at $python."
    }
    if (-not (Test-Path -LiteralPath $mobile)) {
        throw "Flutter project directory is missing at $mobile."
    }

    $adb = Resolve-Adb
    $flutter = Resolve-Flutter -ConfiguredPath $FlutterBin
    $deviceLines = @(& $adb devices -l 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not list Android devices. $($deviceLines | Out-String)"
    }

    $usbDevices = @(
        foreach ($line in $deviceLines) {
            if ($line -match "^(?<id>\S+)\s+device(?:\s+(?<details>.*))?$") {
                $id = $Matches["id"]
                $details = $Matches["details"]
                $networkSerial = $id -match "^(?:\d{1,3}\.){3}\d{1,3}:\d+$"
                $emulatorSerial = $id -match "^emulator-\d+$"
                if ($details -match "\busb:\S+" -or
                    (-not $networkSerial -and -not $emulatorSerial)) {
                    $id
                }
            }
        }
    )
    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        if ($usbDevices.Count -ne 1) {
            throw "Specify -DeviceId when exactly one online USB device is not available. USB devices: $($usbDevices -join ', ')"
        }
        $DeviceId = $usbDevices[0]
    }
    if ($usbDevices -notcontains $DeviceId) {
        throw "Android device '$DeviceId' is not an online USB device. Run 'adb devices -l' first."
    }

    if ([string]::IsNullOrWhiteSpace($HostAddress)) {
        $HostAddress = Resolve-HostAddress
    }
    if (-not (Test-PrivateIpv4 $HostAddress)) {
        throw "HostAddress must be an RFC1918 private IPv4 address."
    }
    $apiBaseUrl = "http://{0}:{1}" -f $HostAddress, $Port

    if (-not $SkipDatabase) {
        Push-Location $root
        try {
            $docker = Get-Command docker -ErrorAction SilentlyContinue
            if ($null -eq $docker) {
                throw "docker was not found. Pass -SkipDatabase if PostgreSQL is already running."
            }
            Invoke-CheckedCommand `
                -FilePath $docker.Source `
                -Arguments @("compose", "up", "-d", "db") `
                -FailureMessage "Could not start PostgreSQL with Docker Compose."
        } finally {
            Pop-Location
        }
    }

    if (-not $SkipMigration) {
        Push-Location $backend
        try {
            Invoke-CheckedCommand `
                -FilePath $python `
                -Arguments @("-m", "alembic", "-c", (Join-Path $backend "alembic.ini"), "upgrade", "head") `
                -FailureMessage "Could not apply backend database migrations."
        } finally {
            Pop-Location
        }
    }

    $logId = [Guid]::NewGuid().ToString("N")
    $stdoutPath = Join-Path ([IO.Path]::GetTempPath()) "safemyanmar-api-$logId.out"
    $stderrPath = Join-Path ([IO.Path]::GetTempPath()) "safemyanmar-api-$logId.err"
    $api = Start-Process `
        -FilePath $python `
        -WorkingDirectory $backend `
        -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", $HostAddress, "--port", "$Port") `
        -PassThru `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath
    Wait-ForApi -Process $api -Url ("{0}/health/live" -f $apiBaseUrl)

    Write-Host ""
    Write-Host "SafeMyanmar backend is running on the LAN."
    Write-Host "Android device: $DeviceId"
    Write-Host "App API URL: $apiBaseUrl"
    Write-Host "Ensure Windows Firewall allows TCP port $Port on the private network."
    Write-Host "Press Ctrl+C to stop Flutter and the backend."
    Write-Host ""

    Push-Location $mobile
    try {
        $flutterArguments = @(
            "run",
            "-d",
            $DeviceId,
            "--dart-define=API_BASE_URL=$apiBaseUrl",
            "--dart-define=ALLOW_INSECURE_LAN_API=true"
        )
        if (-not [string]::IsNullOrWhiteSpace($MapboxPublicAccessToken)) {
            $flutterArguments += "--dart-define=MAPBOX_PUBLIC_ACCESS_TOKEN=$MapboxPublicAccessToken"
        }
        if ($EnableSimulationData) {
            $flutterArguments += "--dart-define=ENABLE_SIMULATION_DATA=true"
        }
        & $flutter @flutterArguments
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter run failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }
} catch {
    $failure = $_.Exception.Message
} finally {
    Stop-Api -Process $api
    if ($null -ne $stdoutPath) {
        Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
    }
    if ($null -ne $stderrPath) {
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

if ($null -ne $failure) {
    Write-Error $failure
    exit 1
}
