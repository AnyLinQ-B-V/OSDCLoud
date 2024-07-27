<#
.SYNOPSIS
Prepare the environment for OSDCloud deployments

.DESCRIPTION
Prepare the environment for OSDCloud deployments.

    # Author: Ronny Roethof
    # Email: ronny.roethof@anylinq.com
    # Copyright: AnyLinQ B.V.
    
    # Based on original work by: Romain Baguet (romain@baguet.org)
    # Source: https://github.com/n4kama/yggdrasil

#>

$Env:GUM_INPUT_CURSOR_FOREGROUND = "#F4AC45"
$Env:GUM_INPUT_PROMPT_FOREGROUND="#04B575"
$Env:GUM_INPUT_WIDTH=200

function New-CustomOSDCloudTemplate {
    <#
    .SYNOPSIS
    Creates an OSDCloud Template by interactively asking the user for the required information.

    .DESCRIPTION
    Uses Gum and New-OSDCloudTemplate function from the OSD module, creates a new OSDCloud Template.
    #>

    # Ask for the language that will be used during the installer and on the laptop
    $ChosenLanguage = gum choose --header "Choose a language" "nl-nl", "en-gb"
    Write-Host -ForegroundColor Green "Language: $ChosenLanguage"

    # Ask if you want to use wifi during the installation or not (Default no)
    gum confirm --default=false "Do you want to use WinRE ? (Enables wireless support. NOT compatible with virtual machines and older systems.)"    
    $UseWinRE = $?

    # Ask for a name that will be used in the templates (Default "AnyLinQ_Laptops")
    #Write-Host -ForegroundColor Yellow "Choose a template name :"
    $TemplateName = gum input --prompt "Choose a template name : " --placeholder "AnyLinQ_Laptops"  --value="AnyLinQ_Laptops"
    if (-not $TemplateName) {
        Write-Host -ForegroundColor Red "Template name is required."
        Exit 1
    }
    else {
        Write-Host -ForegroundColor Green "Template name: $TemplateName"
    }

    # Create the new template using earlier chosesn information
    if (-not $UseWinRE) {
        New-OSDCloudTemplate -Name $TemplateName -Language $ChosenLanguage -SetAllIntl $ChosenLanguage
    }
    else {
        New-OSDCloudTemplate -Name $TemplateName -Language $ChosenLanguage -SetAllIntl $ChosenLanguage -WinRE
    }
}


function New-CustomOSDCloudWorkspace {
    <#
    .SYNOPSIS
    Creates an OSDCloud Workspace by interactively asking the user for the required information.

    .DESCRIPTION
    Uses Gum and New-OSDCloudWorkspace function from the OSD module, creates a new OSDCloud Workspace.
    #>

    # Ask for a workspace name (Default "AnyLinQ_Laptops")
    #Write-Host -ForegroundColor Yellow "Choose a workspace name :"
    $WorkspaceName = gum input --prompt "Choose a workspace name : " --placeholder "AnyLinQ_Laptops" --value="AnyLinQ_Laptops"
    if (-not $WorkspaceName) {
        Write-Host -ForegroundColor Red "Workspace name is required."
        Exit 1
    }
    else {
        Write-Host -ForegroundColor Green "Workspace name: $WorkspaceName"
    }

    New-OSDCloudWorkspace -WorkspacePath "$WorkspacesPath\$WorkspaceName"
}

function Set-StartURL {
    <#
    .SYNOPSIS
    Set the StartURL in the OSDCloud configuration file.

    .DESCRIPTION
    Set the StartURL in the OSDCloud configuration file.
    #>

    # Ask for a startup URL, this contains the powershell script that will be run during OOBE
    #Write-Host -ForegroundColor Yellow "Choose a start URL :"
    $Config.startURL = gum input --prompt "Choose a start URL : " --width=0 --placeholder "https://raw.githubusercontent.com/AnyLinQ-B-V/OSDCloud/main/Automate/Install-Windows.ps1" --value="https://raw.githubusercontent.com/AnyLinQ-B-V/OSDCloud/main/Automate/Install-Windows.ps1"
    write-host -ForegroundColor Green "Start URL: $($Config.startURL)"
}

function Set-Wallpaper {
    <#
    .SYNOPSIS
    Set the wallpaper in the OSDCloud configuration file.

    .DESCRIPTION
    Set the wallpaper in the OSDCloud configuration file.
    #>

    # Ask the wallpaper that will be used during installation
    Write-Host -ForegroundColor Yellow "Choose a wallpaper (Must be in JPEG format) :"
    $Config.wallpaper = gum file $HOME
    write-host -ForegroundColor Green "Wallpaper: $($Config.wallpaper)"
}

#region Ensure that gum is installed
if (-not (Get-Command "gum" -errorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Yellow "Gum is not installed."
    $InstallGum = Read-Host -Prompt "Do you want to install Gum automatically using Scoop? (y/n, default: n)"
    if ($InstallGum -eq "y") { # eq is case insensitive
        Write-Host -ForegroundColor Yellow "Installing Gum..."
        if (-not (Get-Command "scoop" -errorAction SilentlyContinue)) {
            Write-Host -ForegroundColor Yellow "Scoop is not installed."
            $InstallScoop = Read-Host -Prompt "Do you want to install Scoop automatically? (y/n, default: n)"
            if ($InstallScoop -eq "y") {
                Write-Host -ForegroundColor Yellow "Installing Scoop..."
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
                Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin"
                Write-Host -ForegroundColor Yellow "Scoop installed."
            }
            else {
                Write-Host -ForegroundColor Yellow "Please install Scoop manually."
            }
        }
        scoop install charm-gum
        Write-Host -ForegroundColor Yellow "Gum installed."
    }
    else {
        Write-Host -ForegroundColor Yellow "Please install Gum manually."
    }
}
#endregion

#region Ensure that Prepare-OSDCloudEnv.ps1 is run in an elevated PowerShell session
$IsAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if (-not $IsAdmin) {
    Write-Host -ForegroundColor Yellow "Please run this script in an elevated PowerShell session."
    Exit 1
}
# endregion

#region Ensure that OSD module is installed
if (-not (Get-Module -Name OSD -ListAvailable)) {
    Write-Host -ForegroundColor Yellow "OSD module is not installed. Installing..." -NoNewline
    Install-Module -Name 'OSD' -Force | Out-Null
    Write-Host -ForegroundColor Green " Done."
}
#endregion

#region Ensure that Windows ADK is installed
if (-not (Test-Path -Path "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools")) {
    Write-Host -ForegroundColor Yellow "Windows ADK is not installed. Please install Windows ADK."
    Exit 1
}
#endregion

#region Ensure that Windows PE is installed
if (-not (Test-Path -Path "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment")) {
    Write-Host -ForegroundColor Yellow "Windows PE is not installed. Please install Windows PE add-on for the ADK."
    Exit 1
}
#endregion

Write-Host "=== Configure OSDCloud Template and Workspace ==="

#region Setup OSDCloud Template
$CurrentTemplate = Get-OSDCloudTemplate
if (-not $CurrentTemplate) {
    Write-Host -ForegroundColor Yellow "OSDCloud template is not set. Setting up OSDCloud template..."
    New-CustomOSDCloudTemplate
}
else {
    Write-Host -ForegroundColor Yellow "OSDCloud template is set to $CurrentTemplate."
    gum confirm "Do you want to keep it?"
    if (-not $?) {
        $TemplatesList = @("Create new template")
        $TemplatesList += Get-OSDCloudTemplateNames
        $SelectedTemplate = gum choose --header "Choose an existing template or create a new one" $TemplatesList
        if ($SelectedTemplate -eq "Create new template") {
            New-CustomOSDCloudTemplate
        }
        else {
            Set-OSDCloudTemplate -Name $SelectedTemplate | Out-Null
            Write-Host -ForegroundColor Green "OSDCloud template is set to $SelectedTemplate."
        }
    }
}
#endregion

#region Ensure that Workspaces folder exists
$WorkspacesPath = "$env:ProgramData\OSDCloud\Workspaces"
if (-not (Test-Path -Path $WorkspacesPath)) {
    Write-Host -ForegroundColor DarkMagenta "Creating $WorkspacesPath..." -NoNewline
    New-Item -Path $WorkspacesPath -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Green " Done."
}
#endregion

#region Setup OSDCloud Workspace
$CurrentWorkspace = Get-OSDCloudWorkspace
if (-not $CurrentWorkspace) {
    Write-Host -ForegroundColor Yellow "OSDCloud workspace is not set. Setting up OSDCloud workspace..."
    New-CustomOSDCloudWorkspace
    $CurrentWorkspace = Get-OSDCloudWorkspace
}
else {
    Write-Host -ForegroundColor Yellow "OSDCloud workspace is set to $CurrentWorkspace."
    gum confirm "Do you want to keep it?"
    if (-not $?) {
        $WorkspacesList = @("Create new workspace")
        $WorkspacesList += Get-ChildItem $WorkspacesPath | Select-Object -ExpandProperty BaseName
        $SelectedWorkspace = gum choose --header "Choose an existing workspace or create a new one" $WorkspacesList
        if ($SelectedWorkspace -eq "Create new workspace") {
            New-CustomOSDCloudWorkspace
            $CurrentWorkspace = Get-OSDCloudWorkspace
        }
        else {
            Set-OSDCloudWorkspace -WorkspacePath "$WorkspacesPath\$SelectedWorkspace" | Out-Null
            Write-Host -ForegroundColor Green "OSDCloud workspace is set to $SelectedWorkspace."
        }
    }
}
#endregion

#region OSDCloudWinPE customization
Write-Host "=== Editing WinPE in the OSDCloud workspace ==="

#region Read configuration file ($CurrentWorkspace\Config\config.json)
$Config = @{}
$ConfigFile = "$CurrentWorkspace\Config\config.json"
if (Test-Path -Path $ConfigFile) {
    $Config = Get-Content -Path $ConfigFile | ConvertFrom-Json
}
#endregion

#region Configure StartURL
if (-not $Config.startURL) {
    Set-StartURL
}
else {
    Write-Host -ForegroundColor Yellow "Current start URL: $($Config.startURL)"
    gum confirm "Do you want to keep it?"
    if (-not $?) {
        Set-StartURL
    }
}
#endregion

#region Configure wallpaper
$DefaultWallpaper = "$env:windir\Web\Wallpaper\ThemeA\img20.jpg"
if ($Config.wallpaper -and $config.wallpaper -ne $DefaultWallpaper) {
    Write-Host -ForegroundColor Yellow "Current wallpaper: $($Config.wallpaper)"
    gum confirm "Do you want to keep it?"
    if (-not $?) {
        gum confirm --default=false "Do you want to skip setting a wallpaper?"
        if ($?) {
            $Config.wallpaper = $DefaultWallpaper
        }
        else {
            Set-Wallpaper
        }
    }
}
else {
    gum confirm --default=false "Do you want to set a wallpaper?"
    if ($?) {
        Set-Wallpaper
    }
    else {
        $Config.wallpaper = $DefaultWallpaper
    }
}
#endregion

#region Configure the Azure application credentials
if (-not $Config.tenantID) {
    $Config.tenantID = gum input --prompt "Enter the Azure AD tenant Domain : " --width=0 --placeholder "anylinq.com" --value="anylinq.com"
    write-host -ForegroundColor Green "Azure AD tenant ID: $($Config.tenantID)"
}
if (-not $Config.appID) {
    $Config.appID = gum input --prompt "Enter the Azure AD application (client) ID : " --width=0 --placeholder "00000000-0000-0000-0000-000000000000"
    write-host -ForegroundColor Green "Azure AD application ID: $($Config.appID)"
}
if (-not $Config.appSecret) {
    $Config.appSecret = gum input --prompt "Enter the Azure AD application secret value : " --width=0 --password
    write-host -ForegroundColor Green "Azure AD application secret config"
}
if (-not $Config.GroupTag) {
    $Config.GroupTag = gum input --prompt "Enter the Autopilot GroupTag : " --width=0 --placeholder "AQ-AutoDeployed" --value="AQ-AutoDeployed"
    write-host -ForegroundColor Green "Autopilot GroupTag: $($Config.GroupTag)"
}


#endregion

#region Write configuration file ($CurrentWorkspace\Config\config.json)
$Config | ConvertTo-Json | Set-Content -Path $ConfigFile
#endregion

#region Copy WinPE Autopilot prerequisite files
if (-not (Test-Path -Path "$CurrentWorkspace\Config\oa3tool.exe")) {
    Write-Host "Copying OA3 Tool from Windows ADK..." -NoNewline
    Copy-Item -Path "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Licensing\OA30\oa3tool.exe" -Destination "$CurrentWorkspace\Config" -Force
    Write-Host -ForegroundColor Green " Done."
}
if (-not (Test-Path -Path "$CurrentWorkspace\Config\PCPKsp.dll")) {
    Write-Host "Copying PCPKsp.dll from System32..." -NoNewline
    Copy-Item -Path "$env:windir\System32\PCPKsp.dll" -Destination "$CurrentWorkspace\Config\" -Force
    Write-Host -ForegroundColor Green " Done."

}
#endregion

#region Configure WinPE ISO
Edit-OSDCloudWinPE `
-CloudDriver * `
-StartURL $Config.startURL `
-Wallpaper $Config.wallpaper `
-Brand "Anylinq Unattended Laptop Install"
#endregion

#region Configure access rights to the OSDCloud ISO
gum confirm "Allow all users to access the OSDCloud (No prompt) ISO?"
if ($?) {
    $IsoPath = "$CurrentWorkspace\OSDCloud_NoPrompt.iso"
    icacls $IsoPath /grant Everyone:F
    Write-Host -ForegroundColor Green "All users can access the OSDCloud ISO."
}
#endregion

#region Create USB stick
gum confirm "Create USB stick with the OSDCloud (No prompt) ISO?"
if ($?) {
    $IsoPath = "$CurrentWorkspace\OSDCloud_NoPrompt.iso"
    New-OSDCloudUSB -fromIsoFile $IsoPath -Verbose
    Write-Host -ForegroundColor Green "USB Stick created."
}
#endregion

gum style `
	--foreground 212 --border-foreground 212 --border double `
	--align center --width 50 --margin "1 2" --padding "2 4" `
	'=== Done ===!'

Write-Host "=== Done ==="
#endregion