# Setup

## 1. Install prerequisites

- Windows
- WSL
- `tmux`
- Claude Code CLI
- Hermes or another orchestration layer

## 2. Start the bridge helper

Optional first step:

```powershell
Copy-Item .\config\agent-workflow.example.json .\config\agent-workflow.local.json
```

Or do the initial setup in one step:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\install.ps1
```

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\install_startup_helper.ps1
```

Or start the helper manually:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\claude_bridge_helper.ps1
```

The helper watches `%USERPROFILE%\.claude-bridge\trigger.json`.

## 3. Create Claude tmux sessions from WSL

Example:

```bash
tmux new-session -d -s claude-demo -x 160 -y 45
tmux send-keys -t claude-demo 'cd /path/to/project && claude --permission-mode bypassPermissions --dangerously-skip-permissions --allowedTools default' Enter
```

If you want a safer default, start with a more restrictive Claude invocation first and only relax permissions if your workflow actually needs it.

## 4. Emit a visible-monitor trigger

You can either:

- call `scripts/windows/claude_tmux_monitor.ps1` directly, or
- have Hermes write `%USERPROFILE%\.claude-bridge\trigger.json`, or
- reuse `examples/hermes_claude_monitor_hook.py`

See also [USAGE.md](USAGE.md) for privacy-safe local configuration.

## 5. Verify the monitor window

If the bridge is healthy, a new terminal window titled `Claude Monitor: <session>` should open and attach to the tmux session.
