param(
    [string]$BaseUrl,
    [string]$ApiKey,
    [string]$ModelName = "gpt-5.5",
    [string]$LabelOverride = "GPT-5.5 Max",
    [string]$UserDataDir = "$env:LOCALAPPDATA\Claude-3p",
    [string]$ShortcutName = "Claude GPT-5.5 Max",
    [string]$ClaudeExe,
    [switch]$SkipApiTest,
    [switch]$SkipShortcut
)

$ErrorActionPreference = "Stop"

function Expand-ConfigPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [Environment]::ExpandEnvironmentVariables($Path)
}

function Write-Utf8NoBomJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 20
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $json, $encoding)
}

function Backup-IfExists {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$Path.$timestamp.bak"
        Copy-Item -LiteralPath $Path -Destination $backupPath -Force
        Write-Host "Backed up existing file: $backupPath"
    }
}

function Find-ClaudeDesktopExe {
    if ($ClaudeExe) {
        $resolved = Expand-ConfigPath $ClaudeExe
        if (Test-Path -LiteralPath $resolved) {
            return $resolved
        }
        throw "Claude exe was provided but not found: $resolved"
    }

    $windowsApps = Join-Path $env:ProgramFiles "WindowsApps"
    if (Test-Path -LiteralPath $windowsApps) {
        $candidates = @(Get-ChildItem -LiteralPath $windowsApps -Directory -Filter "Claude_*" -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName "app\Claude.exe" } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Sort-Object -Descending)

        if ($candidates) {
            return $candidates[0]
        }
    }

    $localCandidates = @(@(
        "$env:LOCALAPPDATA\Programs\Claude\Claude.exe",
        "$env:ProgramFiles\Claude\Claude.exe",
        "${env:ProgramFiles(x86)}\Claude\Claude.exe"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })

    if ($localCandidates) {
        return $localCandidates[0]
    }

    throw "Could not find Claude Desktop. Pass -ClaudeExe with the full Claude.exe path."
}

function New-ClaudeShortcut {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $desktop = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktop "$Name.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = Split-Path -Parent $TargetPath
    $shortcut.IconLocation = $TargetPath
    $shortcut.Save()

    return $shortcutPath
}

function Test-GatewayModel {
    param(
        [Parameter(Mandatory = $true)][string]$GatewayBaseUrl,
        [Parameter(Mandatory = $true)][string]$GatewayApiKey,
        [Parameter(Mandatory = $true)][string]$GatewayModel
    )

    $uri = $GatewayBaseUrl.TrimEnd("/") + "/v1/messages"
    $headers = @{
        Authorization = "Bearer $GatewayApiKey"
        "Content-Type" = "application/json"
        "anthropic-version" = "2023-06-01"
    }
    $body = @{
        model = $GatewayModel
        max_tokens = 16
        messages = @(
            @{
                role = "user"
                content = "Reply OK."
            }
        )
    } | ConvertTo-Json -Depth 10

    return Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -TimeoutSec 90
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$localConfigPath = Join-Path $repoRoot "config\claude-desktop-gateway.local.json"

if (Test-Path -LiteralPath $localConfigPath) {
    $localConfig = Get-Content -Raw -LiteralPath $localConfigPath | ConvertFrom-Json

    if (-not $BaseUrl -and $localConfig.baseUrl) { $BaseUrl = $localConfig.baseUrl }
    if (-not $ApiKey -and $localConfig.apiKey) { $ApiKey = $localConfig.apiKey }
    if ($localConfig.modelName) { $ModelName = $localConfig.modelName }
    if ($localConfig.labelOverride) { $LabelOverride = $localConfig.labelOverride }
    if ($localConfig.userDataDir) { $UserDataDir = Expand-ConfigPath $localConfig.userDataDir }
    if ($localConfig.shortcutName) { $ShortcutName = $localConfig.shortcutName }
    if (-not $ClaudeExe -and $localConfig.claudeExe) { $ClaudeExe = Expand-ConfigPath $localConfig.claudeExe }
}

if (-not $BaseUrl) {
    throw "Missing BaseUrl. Pass -BaseUrl or create config\claude-desktop-gateway.local.json."
}

if (-not $ApiKey) {
    throw "Missing ApiKey. Pass -ApiKey or create config\claude-desktop-gateway.local.json."
}

$UserDataDir = Expand-ConfigPath $UserDataDir
$claudePath = Find-ClaudeDesktopExe

New-Item -ItemType Directory -Force -Path $UserDataDir | Out-Null
$configLibraryDir = Join-Path $UserDataDir "configLibrary"
New-Item -ItemType Directory -Force -Path $configLibraryDir | Out-Null

$configIdPath = Join-Path $UserDataDir ".gateway-config-id"
if (Test-Path -LiteralPath $configIdPath) {
    $configId = (Get-Content -Raw -LiteralPath $configIdPath).Trim()
} else {
    $configId = [guid]::NewGuid().ToString()
    [System.IO.File]::WriteAllText($configIdPath, $configId, (New-Object System.Text.UTF8Encoding($false)))
}

$inferenceModels = @(
    [ordered]@{
        name = $ModelName
        labelOverride = $LabelOverride
    }
)

$gatewayConfig = [ordered]@{
    id = $configId
    name = "Third-party gateway"
    deploymentMode = "3p"
    inferenceProvider = "gateway"
    inferenceGatewayBaseUrl = $BaseUrl.TrimEnd("/")
    inferenceGatewayApiKey = $ApiKey
    inferenceModels = $inferenceModels
    unstableDisableModelVerification = $true
}

$desktopConfig = [ordered]@{
    deploymentMode = "3p"
    inferenceProvider = "gateway"
    inferenceGatewayBaseUrl = $BaseUrl.TrimEnd("/")
    inferenceGatewayApiKey = $ApiKey
    inferenceModels = $inferenceModels
    unstableDisableModelVerification = $true
}

$desktopConfigPath = Join-Path $UserDataDir "claude_desktop_config.json"
$libraryConfigPath = Join-Path $configLibraryDir "$configId.json"

Backup-IfExists -Path $desktopConfigPath
Backup-IfExists -Path $libraryConfigPath

Write-Utf8NoBomJson -Path $desktopConfigPath -Value $desktopConfig
Write-Utf8NoBomJson -Path $libraryConfigPath -Value $gatewayConfig

if (-not $SkipShortcut) {
    $shortcutPath = New-ClaudeShortcut `
        -TargetPath $claudePath `
        -Arguments "--user-data-dir=`"$UserDataDir`"" `
        -Name $ShortcutName
}

Write-Host "Claude Desktop exe: $claudePath"
Write-Host "User data dir: $UserDataDir"
Write-Host "Desktop config: $desktopConfigPath"
Write-Host "Config library item: $libraryConfigPath"
if ($SkipShortcut) {
    Write-Host "Shortcut: skipped"
} else {
    Write-Host "Shortcut: $shortcutPath"
}

if (-not $SkipApiTest) {
    Write-Host ""
    Write-Host "Testing gateway model route..."
    $response = Test-GatewayModel -GatewayBaseUrl $BaseUrl -GatewayApiKey $ApiKey -GatewayModel $ModelName
    $responseModel = $response.model
    if (-not $responseModel -and $response.responseModel) {
        $responseModel = $response.responseModel
    }

    Write-Host "Gateway responded. Reported model: $responseModel"
}

Write-Host ""
Write-Host "Launch Claude Desktop with:"
Write-Host "`"$claudePath`" --user-data-dir=`"$UserDataDir`""
Write-Host ""
Write-Host "After launch, check logs:"
Write-Host "Select-String -Path `"$UserDataDir\logs\main.log`" -Pattern `"3P mode active|Model discovery|gateway|$ModelName`" | Select-Object -Last 40"
