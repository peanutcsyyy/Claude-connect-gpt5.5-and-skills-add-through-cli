# Claude Desktop GPT-5.5 Gateway

Windows helper and documentation for running Claude Desktop with an isolated third-party `3p` gateway profile.

The default example registers `gpt-5.5` in Claude Desktop and shows it as `GPT-5.5 Max`.

## What It Includes

- an isolated Claude Desktop user data directory pattern
- a PowerShell setup helper for Windows
- a privacy-safe local config template
- UTF-8 without BOM JSON writing
- optional `/v1/messages` route verification
- Desktop shortcut creation with `--user-data-dir`

## Quick Start

Copy the example config:

```powershell
Copy-Item .\config\claude-desktop-gateway.example.json .\config\claude-desktop-gateway.local.json
```

Edit `config\claude-desktop-gateway.local.json` with your own gateway URL and API key.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\configure_claude_desktop_gateway.ps1
```

## Docs

- [Claude Desktop 3P Gateway](docs/CLAUDE_DESKTOP_3P_GATEWAY.md)

## Privacy

This repo is structured so people can use the workflow without publishing their own machine details.

- third-party gateway API keys belong only in `config/claude-desktop-gateway.local.json`
- `config/*.local.json` is ignored by Git
- logs, cache directories, browser state, and tokens should stay out of version control

## Safety

This project is for user-owned local configuration. Do not use it to bypass provider, account, workplace, product, or legal restrictions.

The script can confirm that Claude Desktop requested `gpt-5.5` and that the gateway reported `gpt-5.5`. Whether that is a "full" upstream model depends on the gateway provider's actual routing and limits.

## Status

Clean open-source starter for Claude Desktop third-party gateway setup on Windows.
