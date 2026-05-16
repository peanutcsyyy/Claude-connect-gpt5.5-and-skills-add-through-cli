$ErrorActionPreference = "Stop"

function Get-WorkflowConfigPath {
    $candidates = @()

    if ($env:AGENT_WORKFLOW_CONFIG) {
        $candidates += $env:AGENT_WORKFLOW_CONFIG
    }

    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $candidates += (Join-Path $repoRoot "config\agent-workflow.local.json")
    $candidates += (Join-Path $repoRoot "config\agent-workflow.example.json")

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Get-WorkflowConfig {
    $path = Get-WorkflowConfigPath
    if (-not $path) {
        return [pscustomobject]@{
            bridgeDir = "$env:USERPROFILE\.claude-bridge"
            distro = "Ubuntu"
            helperStartupName = "claude_bridge_helper.cmd"
        }
    }

    $raw = Get-Content -LiteralPath $path -Raw
    $config = $raw | ConvertFrom-Json

    $bridgeDir = "$env:USERPROFILE\.claude-bridge"
    $distro = "Ubuntu"
    $helperStartupName = "claude_bridge_helper.cmd"

    if ($null -ne $config.bridgeDir -and [string]$config.bridgeDir -ne "") {
        $bridgeDir = [string]$config.bridgeDir
    }

    if ($null -ne $config.distro -and [string]$config.distro -ne "") {
        $distro = [string]$config.distro
    }

    if ($null -ne $config.helperStartupName -and [string]$config.helperStartupName -ne "") {
        $helperStartupName = [string]$config.helperStartupName
    }

    return [pscustomobject]@{
        bridgeDir = [Environment]::ExpandEnvironmentVariables($bridgeDir)
        distro = $distro
        helperStartupName = $helperStartupName
    }
}
