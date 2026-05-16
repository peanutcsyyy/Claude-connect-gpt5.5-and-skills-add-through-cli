# Claude Desktop 3P Gateway

This guide shows how to run Claude Desktop on Windows with an isolated third-party gateway configuration.

It is intended for people who already have permission to use their gateway and model endpoint. Do not use it to bypass account, product, provider, or workspace policies.

## What this does

- creates a separate Claude Desktop user data directory
- enables `3p` gateway mode
- registers one visible model label, such as `GPT-5.5 Max`
- writes JSON as UTF-8 without BOM
- creates a Desktop shortcut that always launches Claude with the isolated config
- optionally sends a real `/v1/messages` request to verify the routed model

## Privacy rule

Never commit your real API key or private gateway URL.

Copy the example config to a local ignored file:

```powershell
Copy-Item .\config\claude-desktop-gateway.example.json .\config\claude-desktop-gateway.local.json
```

Then edit `config\claude-desktop-gateway.local.json`:

```json
{
  "baseUrl": "https://your-gateway.example",
  "apiKey": "your-api-key",
  "modelName": "gpt-5.5",
  "labelOverride": "GPT-5.5 Max",
  "userDataDir": "%LOCALAPPDATA%\\Claude-3p",
  "shortcutName": "Claude GPT-5.5 Max"
}
```

`config/*.local.json` is ignored by this repository.

## Configure

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\configure_claude_desktop_gateway.ps1
```

Or pass values directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\configure_claude_desktop_gateway.ps1 `
  -BaseUrl "https://your-gateway.example" `
  -ApiKey "your-api-key" `
  -ModelName "gpt-5.5" `
  -LabelOverride "GPT-5.5 Max"
```

If Claude Desktop is installed in a non-standard place, add:

```powershell
-ClaudeExe "C:\Path\To\Claude.exe"
```

For script tests or headless environments, add:

```powershell
-SkipShortcut
```

## Launch

Use the generated Desktop shortcut, or launch manually:

```powershell
Start-Process "C:\Path\To\Claude.exe" -ArgumentList @("--user-data-dir=$env:LOCALAPPDATA\Claude-3p")
```

The `--user-data-dir` argument matters. Without it, Claude Desktop may use its normal first-party profile instead of the isolated gateway profile.

## Verify

The script can test the gateway by calling:

```text
POST {baseUrl}/v1/messages
```

with:

```text
anthropic-version: 2023-06-01
model: gpt-5.5
```

After Claude Desktop starts, inspect the isolated log:

```powershell
Select-String -Path "$env:LOCALAPPDATA\Claude-3p\logs\main.log" `
  -Pattern "3P mode active|Model discovery|gateway|gpt-5.5" |
  Select-Object -Last 40
```

Useful signs:

- `3P mode active`
- `provider: 'gateway'`
- model discovery finds the configured model
- the gateway test reports `gpt-5.5` as `model` or `responseModel`

## Common issue: Claude Code binary

If the UI shows:

```text
Host Claude Code binary not available. Check that the download completed.
```

that does not necessarily mean model routing failed. It usually means Claude Desktop could not download or verify its local Claude Code host binary.

If you already have a working Claude Code binary, you can seed the Desktop cache with the expected version:

```powershell
$src = "C:\Path\To\@anthropic-ai\claude-code\bin\claude.exe"
$dstDir = "$env:LOCALAPPDATA\Claude-3p\claude-code\2.1.138"
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
Copy-Item -LiteralPath $src -Destination (Join-Path $dstDir "claude.exe") -Force
New-Item -ItemType File -Force -Path (Join-Path $dstDir ".verified") | Out-Null
```

Use the version Claude Desktop requests in its logs.

## Is it the full model?

This setup can confirm that Claude Desktop requested `gpt-5.5` and the gateway responded with `gpt-5.5`.

It cannot prove that the upstream gateway provides a "full" model tier. That depends on the gateway provider's actual upstream model, limits, routing, and account policy.

## Release checklist

Before publishing a fork:

- remove real API keys
- remove private gateway URLs if they are not meant to be public
- remove personal Windows usernames from docs and screenshots
- do not commit `config/*.local.json`
- do not commit Claude logs, browser state, cache directories, or tokens
- keep the project framed as user-owned configuration, not account or policy bypass
