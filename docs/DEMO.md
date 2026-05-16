# Minimal Demo

This is the smallest end-to-end demo for the visible Claude workflow.

## 1. Install the bridge

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\install.ps1
```

## 2. Start the Windows helper

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\claude_bridge_helper.ps1
```

## 3. Create a tmux session in WSL

```bash
tmux new-session -d -s claude-demo -x 160 -y 45
```

## 4. Start Claude in that session

```bash
tmux send-keys -t claude-demo 'cd /path/to/project && claude' Enter
```

## 5. Emit a visible monitor trigger

From Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\claude_tmux_monitor.ps1 -SessionName claude-demo
```

Or from a Hermes-like orchestrator, write a trigger file that contains:

```json
{
  "sessionName": "claude-demo",
  "distro": "Ubuntu",
  "nonce": "demo-001",
  "source": "demo",
  "commandPreview": "tmux send-keys -t claude-demo 'cd /path/to/project && claude' Enter"
}
```

## Expected result

A Windows terminal window titled `Claude Monitor: claude-demo` should open and attach to the tmux session.
