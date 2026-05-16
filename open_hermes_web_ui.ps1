$ErrorActionPreference = "Stop"

$Distro = "Ubuntu"
$Port = 8648
$ProbeAttempts = 25
$ProbeDelayMilliseconds = 700

function Invoke-Wsl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $escaped = $Command.Replace('"', '\"')
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = "wsl.exe"
    $process.StartInfo.Arguments = "-d $Distro -- bash -lc `"$escaped`""
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true

    [void]$process.Start()
    $stdOut = $process.StandardOutput.ReadToEnd()
    $stdErr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdOut
        StdErr = $stdErr
    }
}

function Start-HermesProcess {
    $command = "~/.hermes/node/bin/hermes-web-ui start $Port"
    $escaped = $command.Replace('"', '\"')
    $argumentString = "-d $Distro -- bash -lc `"$escaped`""

    Start-Process -FilePath "wsl.exe" `
        -ArgumentList $argumentString `
        -WindowStyle Hidden | Out-Null
}

function Test-HermesListeningInWsl {
    $listenResult = Invoke-Wsl -Command "ss -ltn 2>/dev/null | grep -q ':$Port '"
    return $listenResult.ExitCode -eq 0
}

function Wait-HermesListeningInWsl {
    for ($i = 0; $i -lt $ProbeAttempts; $i++) {
        if (Test-HermesListeningInWsl) {
            return $true
        }

        Start-Sleep -Milliseconds $ProbeDelayMilliseconds
    }

    return $false
}

function Test-Url {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
    } catch {
        return $false
    }
}

function Wait-HermesOnWindows {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    for ($i = 0; $i -lt $ProbeAttempts; $i++) {
        if (Test-Url $Url) {
            return $true
        }

        Start-Sleep -Milliseconds $ProbeDelayMilliseconds
    }

    return $false
}

function Get-HermesToken {
    $tokenResult = Invoke-Wsl -Command "cat ~/.hermes-web-ui/.token 2>/dev/null || true"
    if ($tokenResult.ExitCode -eq 0) {
        return $tokenResult.StdOut.Trim()
    }

    return $null
}

function Get-WslLocalIp {
    $ipResult = Invoke-Wsl -Command "hostname -I 2>/dev/null | awk '{print `$1}'"
    if ($ipResult.ExitCode -eq 0) {
        return $ipResult.StdOut.Trim()
    }

    return $null
}

function Ensure-HermesBinary {
    $binaryCheck = Invoke-Wsl -Command "test -x ~/.hermes/node/bin/hermes-web-ui"
    if ($binaryCheck.ExitCode -ne 0) {
        throw "hermes-web-ui not found at ~/.hermes/node/bin/hermes-web-ui"
    }
}

function Ensure-HermesReachable {
    $localUrl = "http://127.0.0.1:$Port"

    Ensure-HermesBinary

    if (Test-Url $localUrl) {
        return $localUrl
    }

    if (-not (Test-HermesListeningInWsl)) {
        $startResult = Invoke-Wsl -Command "~/.hermes/node/bin/hermes-web-ui start $Port"
        if ($startResult.ExitCode -ne 0) {
            $details = @(
                "Failed to start Hermes Web UI inside WSL."
                "StdOut: $($startResult.StdOut.Trim())"
                "StdErr: $($startResult.StdErr.Trim())"
            ) -join [Environment]::NewLine

            throw $details
        }

        if (-not (Wait-HermesListeningInWsl)) {
            $logTail = Invoke-Wsl -Command "tail -n 60 /home/c/.hermes-web-ui/server.log 2>/dev/null || true"
            $details = @(
                "Hermes Web UI never started listening on port $Port inside WSL."
                "StdOut: $($startResult.StdOut.Trim())"
                "StdErr: $($startResult.StdErr.Trim())"
                "Recent log:"
                $logTail.StdOut.Trim()
            ) -join [Environment]::NewLine

            throw $details
        }
    }

    if (Wait-HermesOnWindows -Url $localUrl) {
        return $localUrl
    }

    $listeningInWsl = Test-HermesListeningInWsl
    $wslIp = Get-WslLocalIp

    if ($listeningInWsl) {
        $details = @(
            "Hermes Web UI is healthy in WSL, but Windows could not reach $localUrl."
            "This usually means WSL localhost forwarding is temporarily unavailable."
        )

        if ($wslIp) {
            $details += "WSL service address: http://${wslIp}:$Port"
        }

        $details += "If this keeps happening, run `wsl --shutdown` and try again."

        throw ($details -join [Environment]::NewLine)
    }

    $logTail = Invoke-Wsl -Command "tail -n 60 /home/c/.hermes-web-ui/server.log 2>/dev/null || true"
    $details = @(
        "Hermes Web UI exited before Windows could reach it."
        "Recent log:"
        $logTail.StdOut.Trim()
    )

    throw ($details -join [Environment]::NewLine)
}

$localUrl = Ensure-HermesReachable
$urlToOpen = $localUrl
$token = Get-HermesToken

if ($token) {
    $urlToOpen = "$localUrl/#/?token=$token"
}

Start-Process $urlToOpen | Out-Null
