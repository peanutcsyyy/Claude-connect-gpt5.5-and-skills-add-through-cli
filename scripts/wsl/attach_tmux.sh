#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-}"

if [[ -z "$SESSION_NAME" ]]; then
  echo "missing tmux session name"
  exec bash
fi

for _ in $(seq 1 40); do
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    exec tmux attach -t "$SESSION_NAME"
  fi
  sleep 0.25
done

echo "tmux session not found: $SESSION_NAME"
exec bash
