"""Minimal reusable hook for Hermes-like tools to open a visible Claude tmux monitor.

This module is intentionally framework-agnostic. It extracts Claude-related tmux
session names from shell commands and emits a trigger JSON file that the Windows
bridge helper can watch.
"""

from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path

CLAUDE_TMUX_NEW_SESSION_RE = re.compile(
    r"""\btmux\s+new-session\b.*?(?:-s\s+| -s)(['"]?)(?P<name>[A-Za-z0-9._:-]+)\1""",
    re.IGNORECASE,
)

CLAUDE_TMUX_SEND_KEYS_RE = re.compile(
    r"""\btmux\s+send-keys\b.*?(?:-t\s+| -t)(['"]?)(?P<name>[A-Za-z0-9._:-]+)\1.*?\bclaude\b""",
    re.IGNORECASE,
)


def extract_claude_tmux_session(command: str) -> str | None:
    send_keys_match = CLAUDE_TMUX_SEND_KEYS_RE.search(command)
    if send_keys_match:
        return send_keys_match.group("name")

    new_session_match = CLAUDE_TMUX_NEW_SESSION_RE.search(command)
    if new_session_match:
        name = new_session_match.group("name")
        if "claude" in name.lower():
            return name

    return None


def emit_monitor_trigger(
    command: str,
    *,
    bridge_dir: str | os.PathLike[str] = r"/mnt/c/Users/c/.claude-bridge",
    distro: str | None = None,
) -> str | None:
    session_name = extract_claude_tmux_session(command)
    if not session_name:
        return None

    bridge_path = Path(bridge_dir)
    bridge_path.mkdir(parents=True, exist_ok=True)
    trigger_path = bridge_path / "trigger.json"
    tmp_path = bridge_path / "trigger.json.tmp"

    payload = {
        "sessionName": session_name,
        "distro": distro or os.environ.get("WSL_DISTRO_NAME", "Ubuntu"),
        "nonce": f"{int(time.time() * 1000)}-{os.getpid()}-{session_name}",
        "source": "portable-hermes-hook",
        "commandPreview": command[:160],
    }

    tmp_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    tmp_path.replace(trigger_path)
    return session_name


if __name__ == "__main__":
    demo = "tmux send-keys -t claude-demo 'cd /workspace && claude --dangerously-skip-permissions' Enter"
    session = emit_monitor_trigger(demo)
    print(f"triggered: {session}")
