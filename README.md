# Hermes Claude Visible Orchestrator

Visible multi-agent workflow for Windows + WSL where Hermes coordinates and Claude Code does the hands-on coding in a real terminal window.

## Features

- visible Claude Code terminal sessions
- Hermes-as-orchestrator workflow
- WSL + tmux session model
- reusable Windows bridge scripts
- privacy-safe local configuration pattern
- example Hermes trigger hook

## Repository Layout

- `README.md`: project overview
- `LICENSE`: MIT license
- `实时检测Angent工作流.md`: Chinese overview
- `config/agent-workflow.example.json`: config template
- `config/claude-desktop-gateway.example.json`: Claude Desktop gateway template
- `docs/SETUP.md`: installation and setup
- `docs/USAGE.md`: usage and privacy guidance
- `docs/TROUBLESHOOTING.md`: common failure modes
- `docs/HERMES_INTEGRATION.md`: how to wire this into Hermes
- `docs/DEMO.md`: minimal end-to-end demo
- `docs/CLAUDE_DESKTOP_3P_GATEWAY.md`: isolated Claude Desktop 3P gateway setup
- `skills/hermes-claude-visible-orchestrator/SKILL.md`: Hermes skill definition
- `scripts/windows/`: Windows bridge scripts
- `scripts/windows/configure_claude_desktop_gateway.ps1`: Claude Desktop gateway setup helper
- `scripts/wsl/`: WSL bridge script
- `examples/hermes_claude_monitor_hook.py`: portable trigger example

## Quick Start

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\install.ps1
```

Then:

1. review `config/agent-workflow.local.json`
2. start `scripts/windows/claude_bridge_helper.ps1`
3. create a Claude tmux session in WSL
4. launch Claude in that session
5. emit a trigger file or call `claude_tmux_monitor.ps1`

## Docs

- [Setup](docs/SETUP.md)
- [Usage](docs/USAGE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Hermes Integration](docs/HERMES_INTEGRATION.md)
- [Minimal Demo](docs/DEMO.md)
- [Claude Desktop 3P Gateway](docs/CLAUDE_DESKTOP_3P_GATEWAY.md)

## Privacy

This repo is structured so people can publish the workflow without publishing their own machine details.

- machine-specific settings belong in `config/agent-workflow.local.json`
- `config/*.local.json` is ignored by Git
- local startup helpers, logs, databases, and tokens should stay out of version control
- third-party gateway API keys belong only in `config/claude-desktop-gateway.local.json`

## Safety

The example workflow is optimized for low-friction local experimentation, not for high-security environments.

- review Claude permission flags before using them on sensitive repositories
- prefer tighter permissions if you do not need full local autonomy
- do not run this workflow on machines or directories you do not trust

## Status

This is now a reusable open-source starter for the workflow, not just a local note dump. Most users will still need to adapt the Hermes-side trigger integration for their own environment.
