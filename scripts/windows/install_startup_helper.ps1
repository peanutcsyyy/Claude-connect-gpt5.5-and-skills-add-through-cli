$ErrorActionPreference = "Stop"

$configLoader = Join-Path $PSScriptRoot "load_workflow_config.ps1"
if (Test-Path -LiteralPath $configLoader) {
    . $configLoader
    $workflowConfig = Get-WorkflowConfig
} else {
    $workflowConfig = [pscustomobject]@{ helperStartupName = "claude_bridge_helper.cmd" }
}

$startupDir = [Environment]::GetFolderPath("Startup")
$launcherPath = Join-Path $startupDir $workflowConfig.helperStartupName
$helperPath = Join-Path $PSScriptRoot "claude_bridge_helper.ps1"

if (-not (Test-Path -LiteralPath $helperPath)) {
    throw "helper not found: $helperPath"
}

$content = "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$helperPath`"`r`n"
Set-Content -LiteralPath $launcherPath -Value $content -Encoding ASCII

Write-Host "Installed startup launcher to $launcherPath"
