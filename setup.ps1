# Grok Usage Widget — one-command setup.
# Usage:  Right-click → "Run with PowerShell"
#   or:   powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$repo  = $PSScriptRoot
$icon  = Join-Path $repo "grok_widget.ico"
$vbs   = Join-Path $repo "grok_widget.vbs"
$lnk   = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Grok Usage Widget.lnk"

function Need-Command($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "Missing: $name. $hint" -ForegroundColor Red
    exit 1
  }
}

function Get-WidgetProcesses {
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '^pythonw?\.exe$' -and $_.CommandLine -like '*grok_widget.py*'
  }
}

Need-Command python "Install Python 3.10+ from python.org (check 'Add python.exe to PATH', include Tcl/tk)."
Need-Command pythonw "Install Python 3.10+ from python.org (check 'Add python.exe to PATH'). pythonw.exe is required."
Need-Command git    "Install Git from git-scm.com or GitHub Desktop."

$pyVer = & python -c "import sys; print('%d.%d' % sys.version_info[:2])"
if (-not $pyVer) {
  Write-Host "python exists but did not report a version. Reinstall from python.org with 'Add python.exe to PATH'." -ForegroundColor Red
  exit 1
}
$parts = $pyVer.Trim() -split '\.'
$pyMajor = [int]$parts[0]
$pyMinor = [int]$parts[1]
if ($pyMajor -lt 3 -or ($pyMajor -eq 3 -and $pyMinor -lt 10)) {
  Write-Host "Python $pyVer found; 3.10+ is required. Install from python.org with 'Add python.exe to PATH'." -ForegroundColor Red
  exit 1
}

Write-Host "Checking tkinter..." -ForegroundColor Cyan
& python -c "import tkinter" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "tkinter is missing. Reinstall Python from python.org and leave Tcl/tk enabled, with 'Add python.exe to PATH'." -ForegroundColor Red
  exit 1
}

Write-Host "Installing Python dependencies..." -ForegroundColor Cyan
python -m pip install --quiet --user -r (Join-Path $repo "requirements.txt")

if (-not (Test-Path $icon)) {
  Write-Host "Generating widget icon..." -ForegroundColor Cyan
  python (Join-Path $repo "make_icon.py")
}

Write-Host "Creating Start Menu shortcut..." -ForegroundColor Cyan
$wscript = Join-Path $env:SystemRoot "System32\wscript.exe"
$sh  = New-Object -ComObject WScript.Shell
$dir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$shortcut = $sh.CreateShortcut($lnk)
$shortcut.TargetPath       = $wscript
$shortcut.Arguments        = "`"$vbs`""
$shortcut.WorkingDirectory = $repo
if (Test-Path $icon) { $shortcut.IconLocation = $icon }
$shortcut.Description      = "Floating Grok usage widget"
$shortcut.Save()

# "Launch on startup" is opt-in via the widget settings panel.

$existing = @(Get-WidgetProcesses)
if ($existing.Count -gt 0) {
  Write-Host "Widget already running (PID $($existing.ProcessId -join ', ')). Leaving it." -ForegroundColor Green
} else {
  Write-Host "Launching the widget..." -ForegroundColor Cyan
  # Open the shortcut through Explorer so pythonw is not a child of this
  # PowerShell. Agent CLIs (Grok/Claude/Cursor) wrap commands in a Job Object
  # and kill Start-Process children when setup.ps1 exits.
  Start-Process -FilePath (Join-Path $env:SystemRoot "explorer.exe") -ArgumentList "`"$lnk`""
  $deadline = (Get-Date).AddSeconds(8)
  do {
    Start-Sleep -Milliseconds 400
    $existing = @(Get-WidgetProcesses)
  } while ($existing.Count -eq 0 -and (Get-Date) -lt $deadline)

  if ($existing.Count -eq 0) {
    Write-Host "Widget process did not stay running. Crash log (if any): $env:TEMP\grok_widget_error.log" -ForegroundColor Red
    Write-Host "Try the Start Menu shortcut 'Grok Usage Widget', or: python `"$repo\grok_widget.py`"" -ForegroundColor Red
    exit 1
  }
  Write-Host "Widget process running (PID $($existing.ProcessId -join ', '))." -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Look for the floating 'Grok Usage' window (any monitor, often bottom-right)." -ForegroundColor Green
Write-Host "Enable 'Launch on startup' from the widget settings (gear) if you want it at login."
Write-Host "Requires an existing Grok Build login (%USERPROFILE%\.grok\auth.json). Run 'grok login' if needed."
