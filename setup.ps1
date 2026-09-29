# Grok Usage Widget — one-command setup.
# Usage:  Right-click → "Run with PowerShell"
#   or:   powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$repo  = $PSScriptRoot
$icon  = Join-Path $repo "grok_widget.ico"
$vbs   = Join-Path $repo "grok_widget.vbs"

function Need-Command($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "Missing: $name. $hint" -ForegroundColor Red
    exit 1
  }
}

Need-Command python "Install Python 3.10+ from python.org (check 'Add to PATH')."
Need-Command git    "Install Git from git-scm.com or GitHub Desktop."

Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
python -m pip install --quiet --user -r (Join-Path $repo "requirements.txt")

if (-not (Test-Path $icon)) {
  Write-Host "Generating widget icon..." -ForegroundColor Cyan
  python (Join-Path $repo "make_icon.py")
}

Write-Host "Creating Start Menu shortcut..." -ForegroundColor Cyan
$sh  = New-Object -ComObject WScript.Shell
$dir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnk = $sh.CreateShortcut((Join-Path $dir "Grok Usage Widget.lnk"))
$lnk.TargetPath       = "wscript.exe"
$lnk.Arguments        = "`"$vbs`""
$lnk.WorkingDirectory = $repo
if (Test-Path $icon) { $lnk.IconLocation = $icon }
$lnk.Description      = "Floating Grok usage widget"
$lnk.Save()

# Note: "Launch on startup" is opt-in via the widget's settings panel.

Write-Host "Launching the widget..." -ForegroundColor Cyan
Start-Process wscript -ArgumentList "`"$vbs`""

Write-Host ""
Write-Host "Done. Look for the widget in the bottom-right of your screen." -ForegroundColor Green
Write-Host "Enable 'Launch on startup' from the widget settings (≡) if you want it at login."
Write-Host "Requires an existing Grok Build login (~/.grok/auth.json). Run 'grok login' if needed."
