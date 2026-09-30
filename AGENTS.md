# grok-usage-widget — agent instructions

Standing rules for any agent (Grok, Claude Code, Cursor, …) working in this
repo. Read this before installing, editing, or pushing.

This project is a small Windows desktop widget. It is **not** tied to one
person's PC. Every path is relative to the current user's profile.

## Install on this machine (friends / fresh PC)

Trigger: the user asks to set this up, install it, or "get the widget running."

Do this, in order. Stop and tell the user what to install if a step is blocked.

1. **OS.** Windows 10 or 11 only. If this is macOS or Linux, stop and say so.
2. **Python.** `python --version` must be 3.10+. `pythonw` must exist.
   `python -c "import tkinter"` must succeed. If any of those fail, send them
   to https://www.python.org/downloads/windows/ and tell them to check
   **Add python.exe to PATH** (leave Tcl/tk enabled). Do not continue until
   `python` works in a new terminal.
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
   Use `$env:USERPROFILE` (PowerShell) or `Path.home()` (Python) **always**.
   Never infer the home folder from `$env:USERNAME` or `whoami`. The account
   name and the profile folder are often different (USERNAME can be `Joseph`
   while the profile is `C:\Users\josep`).
7. **Setup.** From the clone:
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup.ps1
   ```
   That checks Python/tkinter, installs `requirements.txt`, writes a Start
   Menu shortcut, and launches the widget through Explorer so `pythonw` is
   not a child of this command. Agent CLIs wrap commands in a Job Object and
   will kill `Start-Process` children when the command exits.
8. **Done.** After `setup.ps1` has **fully exited**, confirm `pythonw.exe` is
   still running `grok_widget.py`. If it died, relaunch through Explorer:
   ```powershell
   $lnk = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Grok Usage Widget.lnk"
   Start-Process explorer.exe -ArgumentList "`"$lnk`""
   ```
   A floating Tk window should be visible (any monitor, often bottom-right).
   Do not use PowerShell `$PID` when enumerating windows — it is reserved.
   If the process dies instantly, read `%TEMP%\grok_widget_error.log`.
   Tell the user they can enable **Launch on startup** from the gear in the
   widget. If one copy is already running, leave it.

Do not push, commit, or open a PR as part of install. Do not upload
`auth.json` or `.grok_widget_settings.json`. Do not install extra MCP servers
or skills for this. Do not copy files into `%USERPROFILE%` except via
`setup.ps1`.

If setup fails, paste the PowerShell error and fix that. Common issues:

- `python` / `pythonw` not on PATH → reinstall Python with Add to PATH, new terminal
- `tkinter` missing → reinstall Python with Tcl/tk enabled
- `Not logged in` in the widget → `grok login` on this PC
- Execution policy → already bypassed by the command above
- Widget vanished right after setup printed Done → Job Object killed it;
  relaunch via the Explorer shortcut command in step 8
- Crash at startup → `%TEMP%\grok_widget_error.log`

## Runtime layout

- Repo / live code: the git clone (wherever it is). `grok_widget.vbs` locates
  `grok_widget.py` next to itself.
- Credentials: `%USERPROFILE%\.grok\auth.json` (Grok Build CLI)
- Widget prefs: `%USERPROFILE%\.grok_widget_settings.json`
- Crash log (only on uncaught exception): `%TEMP%\grok_widget_error.log`

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
  Never derive the home folder from `$env:USERNAME`.
