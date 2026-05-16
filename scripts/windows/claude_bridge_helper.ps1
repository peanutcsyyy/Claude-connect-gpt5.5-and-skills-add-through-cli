$ErrorActionPreference = "Stop"

param(
    [string]$BridgeDir,
    [string]$Distro
)

$configLoader = Join-Path $PSScriptRoot "load_workflow_config.ps1"
if (Test-Path -LiteralPath $configLoader) {
    . $configLoader
    $workflowConfig = Get-WorkflowConfig
} else {
    $workflowConfig = [pscustomobject]@{
        bridgeDir = "$env:USERPROFILE\.claude-bridge"
        distro = "Ubuntu"
    }
}

if (-not $BridgeDir) {
    $BridgeDir = $workflowConfig.bridgeDir
}

if (-not $Distro) {
    $Distro = $workflowConfig.distro
}

$triggerPath = Join-Path $BridgeDir "trigger.json"
$statePath = Join-Path $BridgeDir "state.json"
$logPath = Join-Path $BridgeDir "helper.log"
$attachScript = Join-Path $PSScriptRoot "claude_tmux_attach.vbs"

New-Item -ItemType Directory -Force -Path $BridgeDir | Out-Null

if (-not (Test-Path -LiteralPath $statePath)) {
    '{"lastNonce":"","lastSessionName":"","lastOpenedAt":"","status":"idle"}' | Set-Content -Path $statePath -Encoding UTF8
}

function Write-HelperLog {
    param([string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

function Read-State {
    if (-not (Test-Path -LiteralPath $statePath)) {
        return [pscustomobject]@{
            lastNonce = ""
            lastSessionName = ""
            lastOpenedAt = ""
            status = "idle"
        }
    }

    try {
        return Get-Content -Raw -Path $statePath | ConvertFrom-Json
    } catch {
        return [pscustomobject]@{
            lastNonce = ""
            lastSessionName = ""
            lastOpenedAt = ""
            status = "state_corrupt"
        }
    }
}

function Write-State {
    param(
        [string]$LastNonce,
        [string]$LastSessionName,
        [string]$Status
    )

    $state = [pscustomobject]@{
        lastNonce = $LastNonce
        lastSessionName = $LastSessionName
        lastOpenedAt = (Get-Date -Format "s")
        status = $Status
    }

    $state | ConvertTo-Json -Compress | Set-Content -Path $statePath -Encoding UTF8
}

function Open-ClaudeMonitor {
    param(
        [string]$SessionName,
        [string]$ResolvedDistro
    )

    if (-not (Test-Path -LiteralPath $attachScript)) {
        throw "attach script missing: $attachScript"
    }

    $title = "Claude Monitor: $SessionName"
    $wshell = New-Object -ComObject WScript.Shell
    $shellApp = New-Object -ComObject Shell.Application
    $shellApp.ShellExecute("wscript.exe", "`"$attachScript`" `"$SessionName`" `"$ResolvedDistro`"", "", "open", 1)
    Start-Sleep -Milliseconds 900

    try {
        $null = $wshell.AppActivate($title)
    } catch {
    }
}

$mutex = New-Object System.Threading.Mutex($false, "Local\ClaudeBridgeHelper")

try {
    $acquired = $mutex.WaitOne(0, $false)
} catch [System.Threading.AbandonedMutexException] {
    $acquired = $true
    Write-HelperLog "Recovered abandoned mutex."
}

if (-not $acquired) {
    Write-HelperLog "Helper already running; exiting duplicate instance."
    exit 0
}

Write-HelperLog "Helper started."

try {
    $lastSeenWrite = [datetime]::MinValue

    while ($true) {
        try {
            if (Test-Path -LiteralPath $triggerPath) {
                $item = Get-Item -LiteralPath $triggerPath
                if ($item.LastWriteTimeUtc -gt $lastSeenWrite) {
                    $lastSeenWrite = $item.LastWriteTimeUtc
                    $trigger = Get-Content -Raw -Path $triggerPath | ConvertFrom-Json
                    $state = Read-State

                    $nonce = [string]$trigger.nonce
                    $sessionName = [string]$trigger.sessionName
                    $resolvedDistro = if ($trigger.distro) { [string]$trigger.distro } else { $Distro }

                    if (-not $sessionName) {
                        Write-HelperLog "Ignored trigger with empty sessionName."
                    } elseif ($nonce -and $nonce -eq $state.lastNonce) {
                        Write-HelperLog "Ignored duplicate nonce for session $sessionName."
                    } else {
                        Write-HelperLog "Opening visible Claude monitor for session $sessionName."
                        Open-ClaudeMonitor -SessionName $sessionName -ResolvedDistro $resolvedDistro
                        Write-State -LastNonce $nonce -LastSessionName $sessionName -Status "opened"
                    }
                }
            }
        } catch {
            Write-HelperLog ("Loop error: " + $_.Exception.Message)
        }

        Start-Sleep -Milliseconds 400
    }
} finally {
    Write-HelperLog "Helper stopping."
    $mutex.ReleaseMutex() | Out-Null
    $mutex.Dispose()
}
