$mode = Read-Host "wich mode would you like [A]Aoutomatic , [M]Manule"
#===================================VERIABELS================================================================
$git = "$env:ProgramFiles\Git\cmd\git.exe" 
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$vscodesettings = "$env:APPDATA\Code\User\settings.json"
$confirmChanges = $true
#==========================================================================================================

#======================================Functions=======================================================================
function Confirm-Change {
    param(
        [string]$Description
    )
    if (-not $confirmChanges) {
        return $true
    }
    $answer = Read-Host "$Description [Y]Yes [N]No"
    return $answer -match "^[Yy]"
}

function Ensure-JsonFile {
    param(
        [string]$Path
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Content -LiteralPath $Path -Value "{}" -Encoding utf8
    }
}

function gitsetup {
    
    $existingName  = & $git config --global user.name
    $existingEmail = & $git config --global user.email
    $gitname = Read-Host " username for your git (leave blank to keep existing)"
    $gitgmail = Read-Host " Gmail for your git (leave blank to keep existing)"

    if (-not [string]::IsNullOrWhiteSpace($gitname)) {
        & $git config --global user.name $gitname
    }
    elseif (-not $existingName) {
        Write-Host "Git user name was not set" -ForegroundColor Yellow
    }

    if (-not [string]::IsNullOrWhiteSpace($gitgmail)) {
        & $git config --global user.email $gitgmail
    }
    elseif (-not $existingEmail) {
        Write-Host "Git email was not set" -ForegroundColor Yellow
    }
    
    $pullMode = Read-Host "Git pull behavior [R]Rebase [M]Merge [K]Keep existing"
    if ($pullMode -match "^[Rr]") {
        & $git config --global pull.rebase true
    }
    elseif ($pullMode -match "^[Mm]") {
        & $git config --global pull.rebase false
    }
}
function InstallCheckauto{
    param(
        [string]$Name,
        [string]$Id
    )
    winget list --id $Id -e | Out-Null
    if ($LASTEXITCODE -ne 0) {
        if (Confirm-Change "Install $Name?") {
            Write-Host "installing $Name"
            winget install --id $Id -e
        }
        else {
            Write-Host "Skipping $Name" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "$Name is already installed" -ForegroundColor Green
    }
}
function extantioncheck{
    param(
        [string]$extantion,
        [string]$name
    )
    $installed = code --list-extensions | Select-String -SimpleMatch $extantion

    if ($installed) {
        Write-Host "$name is already installed" -ForegroundColor Green
    }
    else {
        if (Confirm-Change "Install $name?") {
            Write-Host "installing $name"
            code --install-extension $extantion
        }
        else {
            Write-Host "Skipping $name" -ForegroundColor Yellow
        }
    }
}


#==========================================================================================================
if ($mode -eq "M")
{
    $applySettings = $true
    extantioncheck -extantion "donjayamanne.python-extension-pack" -name "Python Extension Pack"
    InstallCheckauto -Name "Visual Studeo" -Id "Microsoft.VisualStudio.Community"

    InstallCheckauto -Name "Visual Studeo code" -Id "Microsoft.VisualStudioCode"
    
    InstallCheckauto -Name "Git" -Id "Git.Git"

    InstallCheckauto -Name "Python" -Id "Python.Python.3.13"

    InstallCheckauto -Name "Windows Terminal" -Id "Microsoft.WindowsTerminal"
    InstallCheckauto -Name "PowerShell 7" -Id "Microsoft.PowerShell"
    InstallCheckauto -Name "Node.js LTS" -Id "OpenJS.NodeJS.LTS"

    if (Confirm-Change "Install GitLens?") {
        extantioncheck -extantion "eamodio.gitlens" -name "GitLens"
    }
    if (Confirm-Change "Install C# Dev Kit?") {
        extantioncheck -extantion "ms-dotnettools.csdevkit" -name "C# Dev Kit"
    }

    Ensure-JsonFile -Path $vscodesettings
    Write-Host " Found VS Code settings: $vscodesettings" -ForegroundColor Green


    $save = Read-Host "how loude you like to save the files [A]AutoDali , [O]Off , [W]OfWindollsChange,[F]OfFoucseChange"
    $savemode=""
    if($save -eq "A"){
        $savemode = "afterDelay"
    }
    elseif ($save -eq "O") {
        $savemode = "off"
    }
    elseif ($save -eq "W") {
        $savemode = "onWindowChange"
    }
    elseif ($save -eq "F") {
        $savemode = "onFocusChange"
    }
    
    $Theam = Read-Host "
    Theames wich one wloude you like :
    Default Dark Modern
    Default Light Modern
    Default Dark+
    Default Light+
    Visual Studio Dark
    Visual Studio Light
    Default High Contrast
    Default High Contrast Light
    Monokai
    Monokai Dimmed
    Solarized Dark
    Solarized Light
    Quiet Light
    Abyss
    Kimbie Dark
    Red
    Tomorrow Night Blue
    (TYPE AS IS !!!!) Or skip to keep the defult"
    $pathbar = $false
    $Link = $true
    $check = Read-Host "Do you want the are you sure notifications for visual studeo code  [Y]yes , [N]no"
    if($check -eq "N"){
        $notify = $false
    }
    else {
        $notify = $true
    }
    [int]$size = Read-Host "size of the font"
    if ($size -lt 8 -or $size -gt 40) {
        $size = 10
    }
    [int]$terminalSize = Read-Host "size of the Windows Terminal font (leave blank for 12)"
    if ($terminalSize -lt 8 -or $terminalSize -gt 40) {
        $terminalSize = 12
    }
    $terminalCopy = Read-Host "copy terminal selection to clipboard [Y]Yes [N]No"
    $terminalCopy = $terminalCopy -match "^[Yy]"
    [double]$terminalOpacity = Read-Host "terminal opacity from 0.50 to 1.00 (default 0.85)"
    if ($terminalOpacity -lt 0.50 -or $terminalOpacity -gt 1.00) {
        $terminalOpacity = 0.85
    }
    if (Confirm-Change "Configure Git identity and pull behavior?") {
        gitsetup
    }
    
}
elseif ($mode -eq "A") {
    $applySettings = Confirm-Change "Apply Automatic mode, installs, and settings?"
    if ($applySettings) {
        $confirmChanges = $false
    }
    $size = 10
    $terminalSize = 12
    $terminalCopy = $true
    $terminalOpacity = 0.85
    $savemode="onFocusChange"
    $Theam = "Default Dark+"
    $pathbar = $false
    $Link = $true
    $notify = $true

    if ($applySettings) {
        InstallCheckauto -Name "Visual Studeo" -Id "Microsoft.VisualStudio.Community"
        InstallCheckauto -Name "Visual Studeo code" -Id "Microsoft.VisualStudioCode"
        InstallCheckauto -Name "Git" -Id "Git.Git"
        InstallCheckauto -Name "Python" -Id "Python.Python.3.13"
        InstallCheckauto -Name "Windows Terminal" -Id "Microsoft.WindowsTerminal"
        InstallCheckauto -Name "PowerShell 7" -Id "Microsoft.PowerShell"
        InstallCheckauto -Name "Node.js LTS" -Id "OpenJS.NodeJS.LTS"

        extantioncheck -extantion "donjayamanne.python-extension-pack" -name "Python Extension Pack"
        extantioncheck -extantion "eamodio.gitlens" -name "GitLens"
        extantioncheck -extantion "ms-dotnettools.csdevkit" -name "C# Dev Kit"

        if (Test-Path -LiteralPath $git) {
            & $git config --global pull.rebase false
        }
    }
}


#===========================Terminal===================================================================
if ($applySettings -and (Test-Path -LiteralPath $settingsPath)) {
    if (Confirm-Change "Update Windows Terminal settings?") {
        Copy-Item -LiteralPath $settingsPath -Destination "$settingsPath.bak" -Force
        $jason = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        if (-not $jason.profiles) {
            $jason | Add-Member -MemberType NoteProperty -Name "profiles" -Value ([PSCustomObject]@{}) -Force
        }
        if (-not $jason.profiles.defaults) {
            Write-Host "making defaults section..." -ForegroundColor Red
            $jason.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value ([PSCustomObject]@{}) -Force
        }
        else {
            Write-Host "defaults already exists" -ForegroundColor Green
        }

        $jason.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value ([PSCustomObject]@{ size = $terminalSize; face = "Cascadia Code" }) -Force
        $jason.profiles.defaults | Add-Member -MemberType NoteProperty -Name "copyOnSelect" -Value $terminalCopy -Force
        $jason.profiles.defaults | Add-Member -MemberType NoteProperty -Name "opacity" -Value $terminalOpacity -Force
        Write-Host "terminal font size has been changed to $terminalSize" -ForegroundColor Green

        $jason | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $settingsPath -Encoding utf8
    }
}
else {
    Write-Host "Windows Terminal settings not found; skipping Terminal configuration" -ForegroundColor Yellow
}
#=================================================================================================================

#====================vscode=======================================================================
if ($applySettings) {
    if (Confirm-Change "Update VS Code settings?") {
        Ensure-JsonFile -Path $vscodesettings
        Copy-Item -LiteralPath $vscodesettings -Destination "$vscodesettings.bak" -Force
        $vsJson = Get-Content -LiteralPath $vscodesettings -Raw | ConvertFrom-Json
        $vsJson | Add-Member -MemberType NoteProperty -Name "files.autoSave" -Value $savemode -Force
        $vsJson | Add-Member -MemberType NoteProperty -Name "workbench.colorTheme" -Value $Theam -Force
        $vsJson | Add-Member -MemberType NoteProperty -Name "breadcrumbs.enabled" -Value $pathbar -Force
        $vsJson | Add-Member -MemberType NoteProperty -Name "editor.linkedEditing" -Value $Link -Force
        $vsJson | Add-Member -MemberType NoteProperty -Name "explorer.confirmDelete" -Value $notify -Force
        $vsJson | Add-Member -MemberType NoteProperty -Name "editor.fontSize" -Value $size -Force
        $vsJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $vscodesettings -Encoding utf8
    }
}
