# Setup Launcher

A Windows setup toolkit with a small Tkinter launcher for installing and configuring developer tools or gaming settings.

## Included tools

- **Programming setup:** Installs and configures common development tools, VS Code extensions, VS Code settings, Windows Terminal settings, and Git options.
- **Gaming setup:** Detects graphics hardware and optionally enables Windows Game Mode, High Performance power settings, and hardware-accelerated GPU scheduling.

## Requirements

- Windows 10 or Windows 11
- Python 3.10 or newer to run `setup_launcher.py` from source; the standalone executable bundles Python
- Windows PowerShell or PowerShell 7
- `winget` for package installation
- Administrator access for the gaming setup

The programming setup also requires the `code` command to install VS Code extensions. It asks for confirmation before individual actions in Manual mode.

## Standalone executable

The ready-to-run executable is `dist\SetupLauncher.exe`. It includes the Python runtime and both PowerShell setup scripts, so users do not need to install Python or send the `.ps1` files separately.

The setup features still use Windows PowerShell and `winget`; the programming setup also uses the `code` command to install VS Code extensions. The gaming setup requires administrator access.

To rebuild the executable from the project directory:

```powershell
python -m pip install pyinstaller
python -m PyInstaller --noconfirm --clean .\SetupLauncher.spec
```

## Start the launcher

From this directory, run:

```powershell
python .\setup_launcher.py
```

Choose **Programming setup** or **Gaming setup (administrator)** in the window. Each setup opens in a separate PowerShell window and shows the prompts and actions it performs.

You can also run a setup directly:

```powershell
powershell.exe -NoProfile -File ".\programing.ps1"
```

Run `gaiming.ps1` from an elevated PowerShell window:

```powershell
powershell.exe -NoProfile -File ".\gaiming.ps1"
```

## Programming setup

The script offers two modes:

- **Manual:** You choose whether to apply each install and setting.
- **Automatic:** You approve the overall setup, and missing tools are installed without additional install prompts.

The default automatic configuration uses:

- VS Code auto-save on focus change
- `Default Dark+` VS Code theme
- Editor font size 10
- Windows Terminal font size 12
- Terminal copy-on-select enabled
- Terminal opacity 85%
- Git `pull.rebase` set to `false`

The script can configure or install:

- Visual Studio Community
- Visual Studio Code
- Git
- Python 3.13
- Windows Terminal
- PowerShell 7
- Node.js LTS
- Python Extension Pack
- GitLens
- C# Dev Kit

Existing VS Code and Windows Terminal settings are backed up with a `.bak` suffix before changes are made.

## Gaming setup

The gaming setup offers the same two modes as the programming setup:

- **Manual:** Choose whether to configure apps and confirm each install or Windows setting.
- **Automatic:** Approve the overall setup once; missing apps are installed and the gaming settings below are applied without further prompts.

Both modes detect the operating system and graphics hardware and create an optimization plan on the desktop. The gaming setup prompts for or applies:

- A Windows system restore point
- Steam
- Epic Games Launcher
- Spotify
- Xbox
- Visual C++ Redistributables
- DirectX End-User Runtime
- Windows Game Mode
- High Performance power mode
- Hardware-accelerated GPU scheduling

Before applying changes, registry edits are backed up to:

```text
%LOCALAPPDATA%\GamingSetupBackup
```

The script also creates a gaming optimization plan on the desktop:

```text
Gaming-Optimization-Plan.txt
```

Hardware-accelerated GPU scheduling requires a restart. Use the generated plan and back up important settings before making broad system changes.

## Package installation

If `winget` is missing, install **App Installer** from the Microsoft Store. Package IDs are checked before installation.
