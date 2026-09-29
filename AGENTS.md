# grok-usage-widget — agent instructions

Standing rules for any agent (Grok, Claude Code, Cursor, …) working in this
repo. Read this before installing, editing, or pushing.

This project is a small Windows desktop widget. It is **not** tied to one
person's PC. Every path is relative to the current user's profile.

## Install on this machine (friends / fresh PC)

Trigger: the user asks to set this up, install it, or "get the widget running."

Do this, in order. Stop and tell the user what to install if a step is blocked.

1. **OS.** Windows 10 or 11 only. If this is macOS or Linux, stop and say so.
2. **Python.** `python --version` must be 3.10+. If missing, send them to
   https://www.python.org/downloads/windows/ and tell them to check
   **Add python.exe to PATH**. Do not continue until `python` works in a new
   terminal.
3. **Git.** `git --version`. If missing, send them to
   https://git-scm.com/download/win. Do not continue until `git` works.
4. **Grok CLI.** If `grok` is missing:
   ```powershell
   irm https://x.ai/cli/install.ps1 | iex
   ```
   Then have them restart the terminal (PATH update).
5. **Login on this PC.** The widget reads `%USERPROFILE%\.grok\auth.json`.
   If that file is missing, have the user run `grok login` and wait until the
   file exists. **Never copy `auth.json` from another computer. Never commit it.**
6. **Clone.** If you are not already inside a checkout of
   `https://github.com/JosephBurgan/grok-usage-widget`:
   ```powershell
   git clone https://github.com/JosephBurgan/grok-usage-widget.git "$env:USERPROFILE\grok-usage-widget"
   ```
   Use `$env:USERPROFILE` (PowerShell) or `Path.home()` (Python). Hard-coding
   `C:\Users\Joseph` is wrong unless `whoami` / `$env:USERNAME` is actually
   `Joseph` on **this** machine.
7. **Setup.** From the clone:
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup.ps1
   ```
   That installs `requirements.txt`, writes a Start Menu shortcut, and launches
   `grok_widget.vbs` (pythonw, no console).
8. **Done.** A floating window should appear (often bottom-right). Tell the
   user they can enable **Launch on startup** from ≡ in the widget.

Do not push, commit, or open a PR as part of install. Do not upload
`auth.json` or `.grok_widget_settings.json`. Do not install extra MCP servers
or skills for this. Do not copy files into `%USERPROFILE%` except via
`setup.ps1`.

If setup fails, paste the PowerShell error and fix that. Common issues:

- `python` not on PATH → reinstall Python with Add to PATH, new terminal
- `Not logged in` in the widget → `grok login` on this PC
- Execution policy → already bypassed by the command above
- Widget already running → that's fine; setup launches another copy only if
  the user runs it again

## Runtime layout

- Repo / live code: the git clone (wherever it is). `grok_widget.vbs` locates
  `grok_widget.py` next to itself.
- Credentials: `%USERPROFILE%\.grok\auth.json` (Grok Build CLI)
- Widget prefs: `%USERPROFILE%\.grok_widget_settings.json`
- Nothing else on disk. No log files.

## Versioning (maintainers)

Every commit that ships to users gets a new annotated version tag.

- SemVer. `vMAJOR.MINOR.PATCH`.
  - **PATCH** — bug fix, UX polish, internal refactor
  - **MINOR** — new user-visible feature, added setting
  - **MAJOR** — breaking change (settings shape, removed feature)
- Tag is annotated, message = commit subject:
  ```
  git tag -a vX.Y.Z -m "<one-line summary>"
  git push origin main --follow-tags
  ```
- The widget shows the tag via `git describe --tags`. The in-widget update
  flow fetches `origin/main`. A commit without a tag still updates if they
  pull, but tag anyway so the version label is clean.

## Push workflow (maintainers)

Never push without the repo owner's explicit approval.

1. Edit files in this clone.
2. `python -m py_compile grok_widget.py`
3. Relaunch via `wscript grok_widget.vbs`
4. Owner verifies visually
5. `git add` specific files (not `-A`), commit, tag, push

## Commit style

- One-line, imperative subject. No body unless needed.
- No AI co-author trailer.

## Code style

- Terse. Comments only when the *why* is not obvious.
- Minimal blue. Buttons gray, white text. Green/orange/red only on usage bars.
- All UI mutations via `_after_safe()` so destroyed-window callbacks no-op.
- Paths via `Path.home()` / `Path(__file__)`. Never a hardcoded username.
