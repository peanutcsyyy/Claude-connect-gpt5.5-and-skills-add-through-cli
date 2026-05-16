# Troubleshooting

## A monitor window does not open

Check:

- `scripts/windows/claude_bridge_helper.ps1` is running
- the bridge directory exists
- `trigger.json` is being written
- your tmux session name actually includes `claude` if your hook depends on that pattern

Useful checks:

```powershell
Get-Content $env:USERPROFILE\.claude-bridge\helper.log -Tail 50
Get-Content $env:USERPROFILE\.claude-bridge\trigger.json
```

## The monitor window opens but does not attach

Usually this means:

- the tmux session name is wrong
- the session has not been created yet
- WSL or tmux is missing

Try in WSL:

```bash
tmux ls
```

## Hermes launches Claude but no trigger is emitted

This usually means your Hermes installation does not yet include the tool-level trigger hook.

Use:

- `examples/hermes_claude_monitor_hook.py`
- or emit `%USERPROFILE%\.claude-bridge\trigger.json` manually

## PowerShell scripts fail on another machine

Check:

- execution policy
- WSL installation
- the configured distro name
- whether Windows PowerShell or PowerShell 7 is being used

## Privacy checklist before publishing your own fork

Do not commit:

- `config/agent-workflow.local.json`
- bridge logs
- local database files
- personal usernames hardcoded in paths
- API keys, tokens, or browser cookies
