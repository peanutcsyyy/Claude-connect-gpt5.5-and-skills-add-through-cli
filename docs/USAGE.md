# Usage

## Privacy model

This repository keeps public code and private machine settings separate.

- Public files stay in the repository.
- Private settings go in `config/agent-workflow.local.json`.
- `config/*.local.json` is ignored by Git.

Do not commit:

- personal usernames embedded into paths
- personal project directories
- API keys, tokens, or cookies
- unrelated local startup scripts

## Local configuration

1. Copy `config/agent-workflow.example.json`
2. Rename it to `config/agent-workflow.local.json`
3. Adjust values for your machine

Or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\install.ps1
```

Example:

```json
{
  "bridgeDir": "%USERPROFILE%\\.claude-bridge",
  "distro": "Ubuntu",
  "helperStartupName": "claude_bridge_helper.cmd"
}
```

## Starting the helper

Manual:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\claude_bridge_helper.ps1
```

Startup install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\install_startup_helper.ps1
```

## Triggering the visible Claude monitor

You can trigger the monitor in three ways:

1. Run `scripts/windows/claude_tmux_monitor.ps1` directly
2. Write a trigger JSON file into the bridge directory
3. Reuse `examples/hermes_claude_monitor_hook.py` from your orchestrator

## Expected flow

1. Create a Claude tmux session
2. Launch Claude inside that session
3. Emit the monitor trigger
4. A Windows terminal window opens and attaches to the tmux session

## Hermes integration note

The included Hermes skill describes the orchestration behavior, but each Hermes installation may still need its own tool-level hook to emit trigger JSON automatically.
