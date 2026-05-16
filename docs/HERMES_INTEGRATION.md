# Hermes Integration

## Goal

Hermes should stay responsible for planning and progress summaries, while Claude Code handles the primary coding work in a visible tmux-backed terminal session.

## Minimum integration contract

Your Hermes-side integration should be able to do these things:

1. create or identify a Claude tmux session
2. launch Claude inside that session
3. emit a trigger JSON file for the Windows helper
4. optionally capture the pane and summarize progress

## Trigger file shape

Example:

```json
{
  "sessionName": "claude-demo",
  "distro": "Ubuntu",
  "nonce": "1715410000000-1234-claude-demo",
  "source": "hermes-terminal-tool",
  "commandPreview": "tmux send-keys -t claude-demo 'cd /workspace && claude ...'"
}
```

Write this JSON into:

`%USERPROFILE%\.claude-bridge\trigger.json`

Use an atomic write pattern when possible:

1. write `trigger.json.tmp`
2. rename it to `trigger.json`

## Suggested orchestration sequence

1. `tmux new-session -d -s claude-<task>`
2. launch Claude with permissive flags if appropriate
3. emit the trigger file
4. inject a task file instruction
5. monitor with `tmux capture-pane`

## Example hook

See:

- `examples/hermes_claude_monitor_hook.py`

This hook is intentionally minimal so you can adapt it to your own Hermes fork or wrapper.
