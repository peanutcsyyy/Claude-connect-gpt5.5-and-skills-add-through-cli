---
name: hermes-claude-visible-orchestrator
description: Use when Hermes should act as the planner and orchestrator while Claude Code does the actual coding in a visible terminal window on a Windows plus WSL machine.
version: 1.0.0
author: peanutcsyyy
license: MIT
metadata:
  hermes:
    tags: [Claude-Code, Hermes, visible-terminal, tmux, orchestration, Windows, WSL]
    related_skills: [claude-code, hermes-agent]
---

# Hermes + Claude Visible Orchestrator

Use this skill when Hermes should be the brain and Claude Code should be the hands, with the user watching Claude in a real visible terminal window.

## Goal

Hermes should:

1. decide what work Claude should do
2. launch Claude Code quickly
3. open a visible monitor terminal for the user
4. send the task into Claude
5. monitor progress and summarize back to the user

Claude Code should do the primary coding, debugging, editing, and verification work.

## Hard Rules

- Do not start with Hermes-side investigation, todo planning, or direct code edits unless Claude launch fails.
- Load only the minimum skill context needed, then launch Claude immediately.
- Prefer visible interactive Claude sessions over hidden `claude -p` runs.
- Default to maximum Claude permissions on this machine unless the user explicitly asks for tighter controls.
- If the visible Claude launch fails, say so explicitly before falling back.

## Machine-Specific Launch Path

This machine uses Windows + WSL with local bridge scripts:

- Windows monitor launcher: `C:\Users\c\claude_tmux_monitor.ps1`
- Windows attach wrapper: `C:\Users\c\claude_tmux_attach.cmd`
- WSL attach script: `/home/c/.claude-bridge/attach_tmux.sh`
- Desktop bridge helper: `C:\Users\c\.claude-bridge\claude_bridge_helper.ps1`

Hermes may trigger the visible terminal through the bridge helper, but if needed it can still call the monitor launcher directly.

## Preferred Workflow

### 1. Create a tmux session

Use a descriptive session name, for example:

- `claude-<project>-bugfix`
- `claude-<project>-review`
- `claude-<project>-followup`

### 2. Open the visible monitor terminal immediately

Use the machine's monitor launcher right after the tmux session is created.

### 3. Launch Claude Code with maximum permissions

Launch Claude from the project directory with:

- `--permission-mode bypassPermissions`
- `--dangerously-skip-permissions`
- `--allowedTools default`

### 4. Handle first-run dialogs

If trust or bypass dialogs appear, Hermes should clear them automatically so the visible session can proceed without stalling.

### 5. Send the task through a project-local prompt file

Do not rely on `/tmp` for non-trivial prompts. Write a project-local task file such as:

- `.hermes_claude_task.txt`
- `.hermes_claude_followup.txt`

Then instruct Claude to read that file and execute it.

## Monitoring Rules

- Treat the visible Claude terminal as the primary live view.
- Hermes should still monitor via `tmux capture-pane` and summarize important state.
- Do not assume Claude is stuck without checking the pane first.

## When To Use This Skill

Use this skill when the user wants:

- Claude to do the coding work
- Hermes to coordinate instead of directly coding
- a visible Claude terminal
- live monitoring during debugging, bug-fixing, or code review

## Fallback Behavior

If visible Claude launch fails:

1. state clearly that the visible Claude session failed to launch
2. report which step failed
3. only then fall back to Hermes-side coding or hidden Claude execution
