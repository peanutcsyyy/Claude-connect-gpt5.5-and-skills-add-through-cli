$ErrorActionPreference = "Stop"

param(
    [Parameter(Mandatory = $true)]
    [string]$SessionName,

    [string]$Distro,

    [string]$AttachWrapperPath
)

$configLoader = Join-Path $PSScriptRoot "load_workflow_config.ps1"
if (Test-Path -LiteralPath $configLoader) {
    . $configLoader
    $workflowConfig = Get-WorkflowConfig
} else {
    $workflowConfig = [pscustomobject]@{ distro = "Ubuntu" }
}

if (-not $Distro) {
    $Distro = $workflowConfig.distro
}

if (-not $AttachWrapperPath) {
    $AttachWrapperPath = Join-Path $PSScriptRoot "claude_tmux_attach.cmd"
}

if (-not (Test-Path -LiteralPath $AttachWrapperPath)) {
    throw "attach wrapper not found: $AttachWrapperPath"
}

$arguments = @(
    "/k"
    "`"$AttachWrapperPath`""
    "`"$SessionName`""
    "`"$Distro`""
)

Start-Process -FilePath "cmd.exe" -ArgumentList $arguments | Out-Null
