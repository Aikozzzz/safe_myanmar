[CmdletBinding()]
param(
    [string]$DeviceId = "",
    [ValidateRange(1, 65535)]
    [int]$Port = 8000,
    [switch]$SkipDatabase,
    [switch]$SkipMigration
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"
$python = Join-Path $backend ".venv\Scripts\python.exe"
$packageName = "org.safemyanmar.mobile"
$api = $null
$adb = $null
$reverseConfigured = $false
$failure = $null
$logId = [Guid]::NewGuid().ToString("N")
$stdoutPath = Join-Path ([IO.Path]::GetTempPath()) "safemyanmar-api-$logId.out"
$stderrPath = Join-Path ([IO.Path]::GetTempPath()) "safemyanmar-api-$logId.err"

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

function Get-CommandPath {
    param([Parameter(Mandatory = $true)][string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "$Name was not found on PATH."
    }
    return $command.Source
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$FailureMessage = "Command failed."
    )

    $output = @(& $FilePath @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $details = ($output | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($details)) {
            throw $FailureMessage
        }
        throw "$FailureMessage $details"
    }
    return ($output | Out-String).Trim()
}

function Wait-ForApi {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 20
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        $Process.Refresh()
        if ($Process.HasExited) {
            $stderr = if (Test-Path -LiteralPath $stderrPath) {
                Get-Content -LiteralPath $stderrPath -Raw
            } else {
                ""
            }
            $message = ("The backend stopped before becoming ready. $stderr").Trim()
            throw $message
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

    $stderr = if (Test-Path -LiteralPath $stderrPath) {
        Get-Content -LiteralPath $stderrPath -Raw
    } else {
        ""
    }
    $message = ("The backend did not become ready within $TimeoutSeconds seconds. $stderr").Trim()
    throw $message
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

    $adb = Resolve-Adb
    $deviceLines = @(& $adb devices 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not list Android devices. $($deviceLines | Out-String)"
    }

    $onlineDevices = @(
        foreach ($line in $deviceLines) {
            if ($line -match "^(?<id>\S+)\s+device$") {
                $Matches["id"]
            }
        }
    )

    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        if ($onlineDevices.Count -ne 1) {
            throw "Specify -DeviceId. Online devices: $($onlineDevices -join ', ')"
        }
        $DeviceId = $onlineDevices[0]
    }

    if ($onlineDevices -notcontains $DeviceId) {
        throw "Android device '$DeviceId' is not online in adb. Run 'adb devices' first."
    }

    $packagePath = @(
        & $adb -s $DeviceId shell pm path $packageName 2>&1
    )
    if ($LASTEXITCODE -ne 0 -or
        -not ($packagePath | Where-Object { $_ -match "^package:" })) {
        throw "The installed app package '$packageName' was not found on $DeviceId."
    }

    if (-not $SkipDatabase) {
        $docker = Get-CommandPath "docker"
        Invoke-CheckedCommand `
            -FilePath $docker `
            -Arguments @("compose", "up", "-d", "db") `
            -FailureMessage "Could not start PostgreSQL with Docker Compose."
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

    Invoke-CheckedCommand `
        -FilePath $adb `
        -Arguments @("-s", $DeviceId, "reverse", "tcp:$Port", "tcp:$Port") `
        -FailureMessage "Could not configure wireless adb reverse forwarding."
    $reverseConfigured = $true

    $api = Start-Process `
        -FilePath $python `
        -WorkingDirectory $backend `
        -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "$Port") `
        -PassThru `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    Wait-ForApi -Process $api -Url "http://127.0.0.1:$Port/health/live"

    Write-Host ""
    Write-Host "SafeMyanmar backend is running for the already-installed app."
    Write-Host "Android device: $DeviceId"
    Write-Host "App API URL must be: http://127.0.0.1:$Port"
    Write-Host "Backend URL on this computer: http://127.0.0.1:$Port"
    Write-Host "Press Ctrl+C to stop the backend and remove adb reverse forwarding."
    Write-Host ""

    while ($true) {
        $api.Refresh()
        if ($api.HasExited) {
            $stderr = if (Test-Path -LiteralPath $stderrPath) {
                Get-Content -LiteralPath $stderrPath -Raw
            } else {
                ""
            }
            $message = ("The backend stopped unexpectedly. $stderr").Trim()
            throw $message
        }
        Start-Sleep -Seconds 1
    }
} catch {
    $failure = $_.Exception.Message
} finally {
    Stop-Api -Process $api

    if ($reverseConfigured -and $null -ne $adb) {
        & $adb -s $DeviceId reverse --remove "tcp:$Port" *> $null
    }

    Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
}

if ($null -ne $failure) {
    Write-Error $failure
    exit 1
}
