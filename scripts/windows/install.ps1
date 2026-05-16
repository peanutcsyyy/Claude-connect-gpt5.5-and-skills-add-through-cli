$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$configDir = Join-Path $repoRoot "config"
$exampleConfig = Join-Path $configDir "agent-workflow.example.json"
$localConfig = Join-Path $configDir "agent-workflow.local.json"
$helperScript = Join-Path $PSScriptRoot "claude_bridge_helper.ps1"
$startupInstaller = Join-Path $PSScriptRoot "install_startup_helper.ps1"

if (-not (Test-Path -LiteralPath $exampleConfig)) {
    throw "example config not found: $exampleConfig"
}

if (-not (Test-Path -LiteralPath $localConfig)) {
    Copy-Item -LiteralPath $exampleConfig -Destination $localConfig
    Write-Host "Created local config: $localConfig"
} else {
    Write-Host "Local config already exists: $localConfig"
}

. (Join-Path $PSScriptRoot "load_workflow_config.ps1")
$workflowConfig = Get-WorkflowConfig

New-Item -ItemType Directory -Force -Path $workflowConfig.bridgeDir | Out-Null
Write-Host "Ensured bridge directory exists: $($workflowConfig.bridgeDir)"

if (-not (Test-Path -LiteralPath $helperScript)) {
    throw "helper script not found: $helperScript"
}

& $startupInstaller

Write-Host ""
Write-Host "Installation complete."
Write-Host "Next steps:"
Write-Host "1. Review and edit $localConfig if needed."
Write-Host "2. Start the helper now with:"
Write-Host "   powershell -ExecutionPolicy Bypass -File `"$helperScript`""
Write-Host "3. Create a Claude tmux session in WSL and emit a trigger."
