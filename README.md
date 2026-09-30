# Grok Usage Widget

![widget](grok_widget.png)

A small always-on-top floating window for Windows that shows your SuperGrok /
Grok Build plan usage (weekly pool, per-product breakdown, on-demand / prepaid
when present) with live progress bars and a reset countdown. Refreshes every
few minutes (configurable).

## Features

- Always-on-top floating window — drag by the title bar to position
- Live progress bars colored by usage level (green / orange / red)
- Countdown to the weekly (or monthly) reset
- Per-product rows (Chat, Build, Imagine, …) when the API returns them
- Click the pin (📌) to toggle always-on-top
- Click the gear (≡) to hide rows, set refresh interval, and launch-on-startup

## Requirements

- Windows 10 or 11
- Python 3.10+ ([install from python.org](https://www.python.org/downloads/windows/) — make sure "Add to PATH" is checked)
- Git ([git-scm.com](https://git-scm.com/download/win) or GitHub Desktop)
- [Grok Build CLI](https://docs.x.ai) authenticated at least once
  (the widget reads tokens from `~/.grok/auth.json`)

This is your login on **this** PC. Do not copy `auth.json` from another machine.

## Easiest: ask Grok to install it

If you already have Grok Build on the PC, paste this into Grok. It works on a
fresh Windows machine — Grok will use *your* user folder, not the author's.

```
Please install the Grok Usage Widget on this Windows PC.

Public repo: https://github.com/JosephBurgan/grok-usage-widget

This is my machine. Use $env:USERPROFILE (PowerShell) or Path.home() (Python) for every path.
Never infer the home folder from $env:USERNAME or whoami — the account name and the profile folder are often different (example: USERNAME=Joseph, profile=C:\Users\josep).

1. Confirm Windows 10/11.
2. If python is missing or older than 3.10, or pythonw / tkinter is missing, tell me to install Python from python.org with "Add python.exe to PATH" (leave Tcl/tk enabled), then stop so I can retry.
3. If git is missing, tell me to install Git from git-scm.com, then stop so I can retry.
4. If the grok command is missing, install Grok Build with:
   irm https://x.ai/cli/install.ps1 | iex
   then have me restart the terminal.
5. If %USERPROFILE%\.grok\auth.json is missing, have me run: grok login
   Wait until that file exists. Never copy auth.json from another computer.
6. Clone the repo to %USERPROFILE%\grok-usage-widget if that folder is not already a git checkout of this repo.
7. Read AGENTS.md in the clone, then from that folder run:
   powershell -ExecutionPolicy Bypass -File setup.ps1
8. After that command has fully exited, confirm pythonw.exe is still running grok_widget.py.
   If it died, relaunch through Explorer (so it outlives the agent Job Object):
     $lnk = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Grok Usage Widget.lnk"
     Start-Process explorer.exe -ArgumentList "`"$lnk`""
   Confirm a visible Tk window. Do not use PowerShell $PID when enumerating windows (it is reserved).
   Do not commit, push, or upload credentials.

Do not edit source unless setup fails. Do not put secrets in the repo.
```

Grok follows `AGENTS.md` once the repo is on disk. The prompt above is enough
to get there on a machine that has never seen this project.

## Install yourself

```powershell
git clone https://github.com/JosephBurgan/grok-usage-widget.git "$env:USERPROFILE\grok-usage-widget"
cd $env:USERPROFILE\grok-usage-widget
powershell -ExecutionPolicy Bypass -File setup.ps1
```

The setup script checks Python 3.10+ / pythonw / tkinter, installs Python
dependencies, creates a Start Menu shortcut (with the widget icon), and
launches the widget through Explorer so it keeps running after the setup
command exits.

If you have not logged into Grok Build on this PC yet:

```powershell
irm https://x.ai/cli/install.ps1 | iex
grok login
```

Then run `setup.ps1` again.

## Update

Click ≡ on the widget → **Check for updates** → if available, click **Update**.
That runs `git pull` and relaunches the widget automatically.

Or manually:

```powershell
cd $env:USERPROFILE\grok-usage-widget
git pull
```

## How it works

- Reads the OAuth access + refresh tokens from `~/.grok/auth.json`
- Refreshes the access token automatically via `POST https://auth.x.ai/oauth2/token`
  when it's close to expiring
- Polls `GET https://cli-chat-proxy.grok.com/v1/billing?format=credits` with
  `Authorization: Bearer <token>` and `x-xai-token-auth: xai-grok-cli`
- Optionally reads plan name from `/v1/settings` (`subscription_tier_display`)
- Writes refreshed tokens back to the credentials file

This is a billing/metadata call — it does **not** consume your weekly usage
pool or prepaid API credits.

If the refresh token ever gets invalidated, the widget will show "Not logged
in" — run `grok login` once and the tokens will be refreshed.

Per-window preferences are stored at
`%USERPROFILE%\.grok_widget_settings.json`.

## Icon

`make_icon.py` builds `grok_widget.ico` from the Grok mark in `grok_mark.svg`
(stylized G / singularity logo) plus the green usage bars. Regenerate with:

```powershell
python -m pip install -r requirements-dev.txt
python make_icon.py
```

## License

MIT
