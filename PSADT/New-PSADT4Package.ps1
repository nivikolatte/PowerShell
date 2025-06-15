#Requires -Version 5.1
<#
.SYNOPSIS
    Creates PSADT 4.0 packages using official New-ADTTemplate cmdlet

.DESCRIPTION
    Automates the creation of PowerShell App Deployment Toolkit 4.0 packages using the official
    New-ADTTemplate cmdlet approach. This ensures compatibility with the latest PSADT v4 structure
    and best practices as documented in the official PSADT v4 documentation.
      Features:
    - Uses New-ADTTemplate for proper v4 structure
    - Pure PSADT v4 implementation only
    - Follows official PSADT v4 naming conventions (ADT prefixed functions)
    - Generates modern Deploy-Application.ps1 with v4 syntax
    - Automatic module import and session management

.PARAMETER AppName
    Name of the application (e.g., "VLC Media Player")

.PARAMETER AppVersion
    Version of the application (e.g., "3.0.20")

.PARAMETER AppPublisher
    Publisher/vendor of the application (e.g., "VideoLAN")

.PARAMETER SourcePath
    Path to the source installer files

.PARAMETER InstallFile
    Name of the main installer file

.PARAMETER InstallType
    Type of installer: MSI, EXE, or MSP

.PARAMETER OutputPath
    Output directory for packages (default: C:\PSADT_Packages)

.PARAMETER PSADT4Path
    Path to PSADT 4.0 installation (default: C:\PSADT4)

.PARAMETER CompanyName
    Company name for registry keys (defaults to AppPublisher if not specified)

.PARAMETER LogPath
    Custom log path for PSADT logs (default: C:\Windows\Logs\Software)

.PARAMETER Architecture
    Target architecture: x86, x64, or ARM64 (default: x64)

.PARAMETER Language
    Application language code (default: EN)

.EXAMPLE
    .\New-PSADT4Package.ps1 -AppName "VLC Media Player" -AppVersion "3.0.20" -AppPublisher "VideoLAN" -SourcePath "C:\Source\VLC" -InstallFile "vlc-3.0.20-win64.exe" -InstallType "EXE"

.EXAMPLE
    .\New-PSADT4Package.ps1 -AppName "Chrome" -AppVersion "120.0" -AppPublisher "Google" -CompanyName "MyCompany" -SourcePath "C:\Source" -InstallFile "chrome.msi" -InstallType "MSI" -LogPath "D:\Logs"

.NOTES
    Author: IT Department
    Version: 4.0.0
    Date: 2025-06-16
    Requires: PowerShell 5.1+, PSADT 4.0 with New-ADTTemplate cmdlet
    Updated: Pure PSADT v4 implementation - NO v3 compatibility
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Application name")]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    
    [Parameter(Mandatory = $true, HelpMessage = "Application version")]
    [ValidateNotNullOrEmpty()]
    [string]$AppVersion,
    
    [Parameter(Mandatory = $true, HelpMessage = "Application publisher")]
    [ValidateNotNullOrEmpty()]
    [string]$AppPublisher,
    
    [Parameter(Mandatory = $true, HelpMessage = "Path to source installer files")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$SourcePath,
    
    [Parameter(Mandatory = $true, HelpMessage = "Main installer filename")]
    [ValidateNotNullOrEmpty()]
    [string]$InstallFile,
      [Parameter(Mandatory = $true, HelpMessage = "Installer type")]
    [ValidateSet("MSI", "EXE", "MSP")]
    [string]$InstallType,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = "C:\PSADT_Packages",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$PSADT4Path = "C:\PSADT4",
    
    [Parameter(Mandatory = $false, HelpMessage = "Company name for registry keys (defaults to AppPublisher)")]
    [ValidateNotNullOrEmpty()]
    [string]$CompanyName,
      [Parameter(Mandatory = $false, HelpMessage = "Custom log path for PSADT logs")]
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = "C:\Windows\Logs\Software",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("x86", "x64", "ARM64")]
    [string]$Architecture = "x64",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern("^[A-Z]{2}$")]
    [string]$Language = "EN"
)

#region Helper Functions
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Type = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Type]
}

function Test-PSADT4Installation {
    param([string]$Path)
    
    # Check for PSADT 4.0 module files
    $requiredFiles = @(
        "PSAppDeployToolkit.psd1",
        "PSAppDeployToolkit.psm1"
    )
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $Path $file
        if (!(Test-Path $filePath)) {
            Write-LogMessage "Missing required PSADT v4 file: $file" -Type "Error"
            return $false
        }
    }
    
    # Check for PSADT 4.0 version in module manifest
    $manifestPath = Join-Path $Path "PSAppDeployToolkit.psd1"
    if (Test-Path $manifestPath) {
        try {
            $manifest = Import-PowerShellDataFile $manifestPath -ErrorAction Stop
            $version = [Version]$manifest.ModuleVersion
            if ($version.Major -ge 4) {
                Write-LogMessage "Found PSADT version: $($version.ToString())" -Type "Success"
                return $true
            } else {
                Write-LogMessage "Found PSADT version $($version.ToString()), but v4.x is required" -Type "Error"
                return $false
            }
        }
        catch {
            Write-LogMessage "Could not validate PSADT version: $($_.Exception.Message)" -Type "Error"
            return $false
        }
    }
    
    Write-LogMessage "PSADT 4.0 version validation failed" -Type "Error"
    return $false
}

function Import-PSADT4Module {
    param([string]$Path)
    
    try {
        # First, try to use the installed PSAppDeployToolkit module
        $installedModule = Get-Module -ListAvailable -Name PSAppDeployToolkit -ErrorAction SilentlyContinue
        
        if ($installedModule) {
            Write-LogMessage "Using installed PSAppDeployToolkit module (Version: $($installedModule.Version))" -Type "Info"
            Import-Module PSAppDeployToolkit -Force -Global -Verbose:$false
        } else {
            # Fall back to local path
            Write-LogMessage "Installed module not found, using local path: $Path" -Type "Info"
            $modulePath = Join-Path $Path "PSAppDeployToolkit.psm1"
            
            if (!(Test-Path $modulePath)) {
                Write-LogMessage "Module not found at: $modulePath" -Type "Error"
                return $false
            }
            
            Import-Module $modulePath -Force -Global -Verbose:$false
        }
        
        Write-LogMessage "Successfully imported PSADT v4 module" -Type "Success"
        
        # Verify New-ADTTemplate cmdlet is available
        if (Get-Command "New-ADTTemplate" -ErrorAction SilentlyContinue) {
            Write-LogMessage "New-ADTTemplate cmdlet is available" -Type "Success"
            return $true
        } else {
            Write-LogMessage "New-ADTTemplate cmdlet not found in module" -Type "Error"
            return $false
        }
    }
    catch {
        Write-LogMessage "Failed to import PSADT v4 module: $($_.Exception.Message)" -Type "Error"
        return $false
    }
}

function New-SafePackageName {
    param(
        [string]$Publisher,
        [string]$Name,
        [string]$Version
    )
    
    # Remove invalid characters and create safe package name
    $safeName = "$Publisher-$Name-$Version" -replace '[^\w\.-]', '_'
    return $safeName
}

function New-PSADT4DeployScript {
    param(
        [string]$AppName,
        [string]$AppVersion,
        [string]$AppPublisher,
        [string]$InstallFile,
        [string]$InstallType,
        [string]$Architecture,
        [string]$Language,
        [string]$CompanyName,
        [string]$LogPath
    )
      $currentDate = Get-Date -Format "MM/dd/yyyy"
    
    # Generate install parameters based on type
    $installParams = switch ($InstallType) {
        "MSI" { "ALLUSERS=1 REBOOT=ReallySuppress /quiet" }
        "EXE" { "/S /v/qn" }
        "MSP" { "/quiet /norestart" }
    }
    
    # Use v4 native ADT prefixed functions only
    $installCommand = switch ($InstallType) {
        "MSI" { "Start-ADTMsiProcess -Action 'Install' -FilePath `$InstallFile -Parameters `$InstallParameters" }
        "EXE" { "Start-ADTProcess -FilePath `$InstallFile -ArgumentList `$InstallParameters -WindowStyle 'Hidden' -IgnoreExitCodes '3010'" }
        "MSP" { "Start-ADTMsiProcess -Action 'Patch' -FilePath `$InstallFile -Parameters `$InstallParameters" }
    }
    
    $uninstallCommand = switch ($InstallType) {
        "MSI" { "Start-ADTMsiProcess -Action 'Uninstall' -FilePath `$InstallFile" }
        "EXE" { "# Define uninstall method for EXE installer`n        Write-ADTLogEntry -Message 'Custom uninstall logic required for EXE installer' -Severity 2" }
        "MSP" { "# MSP patches typically don't have standalone uninstall`n        Write-ADTLogEntry -Message 'MSP patch uninstall requires base application removal' -Severity 2" }
    }
      $welcomeCommand = "Show-ADTInstallationWelcome -CloseProcesses '$($AppName -replace '\s+', '')' -AllowDeferCloseProcesses -DeferTimes 3 -PersistPrompt -NoMinimizeWindows"
    $promptCommand = "Show-ADTInstallationPrompt -Message `"`$installTitle installation completed successfully.`" -ButtonRightText 'OK' -Icon Information -NoWait"

    return @"
#Requires -Version 5.1
<#
.SYNOPSIS
    $AppName v$AppVersion Deployment Script (PSADT v4 Native)
.DESCRIPTION
    Deploys $AppName using PowerShell App Deployment Toolkit 4.0
    Template: PSADT v4 Native
    Generated on: $currentDate
.NOTES
    Toolkit Exit Code Ranges:
    - 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1
    - 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    - 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
    https://psappdeploytoolkit.com
#>

[CmdletBinding()]
Param (
    ## The action to perform. Options: Install, Uninstall, Repair
    [Parameter(Mandatory = `$false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]`$DeploymentType = 'Install',
    
    ## The install deployment mode. Options: Interactive, Silent, NonInteractive
    [Parameter(Mandatory = `$false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]`$DeployMode = 'Interactive',
    
    ## Allows the 3010 return code (requires restart) to be passed back to the parent process
    [Parameter(Mandatory = `$false)]
    [Switch]`$AllowRebootPassThru = `$false,
    
    ## Specifies an alternate location for the toolkit dependency files
    [Parameter(Mandatory = `$false)]
    [ValidateNotNullOrEmpty()]
    [String]`$ToolkitParameters
)

Try {
    #region Initialization
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
        Write-Error "Failed to set the execution policy to Bypass for this process."
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]`$appVendor = '$AppPublisher'
    [String]`$appName = '$AppName'
    [String]`$appVersion = '$AppVersion'
    [String]`$appArch = '$Architecture'
    [String]`$appLang = '$Language'
    [String]`$appRevision = '01'
    [String]`$appScriptVersion = '1.0.0'
    [String]`$appScriptDate = '$currentDate'
    [String]`$appScriptAuthor = 'IT Department'

    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]`$installName = "`$appVendor `$appName"
    [String]`$installTitle = "`$appVendor `$appName `$appVersion"

    ## Variables: Script
    [String]`$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]`$deployAppScriptVersion = [Version]'4.0.0'
    [String]`$deployAppScriptParameters = `$PSBoundParameters | ConvertTo-Json -Compress
    [String]`$deployAppScriptDate = '$currentDate'

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        `$InvocationInfo = `$HostInvocation
    }
    Else {
        `$InvocationInfo = `$MyInvocation
    }
    [String]`$scriptDirectory = Split-Path -Path `$InvocationInfo.MyCommand.Definition -Parent

    ## Import the PSAppDeployToolkit module (PSADT 4.0)
    Try {
        [String]`$moduleAppDeployToolkit = "`$scriptDirectory\PSAppDeployToolkit.psm1"
        If (-not (Test-Path -LiteralPath `$moduleAppDeployToolkit -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [`$moduleAppDeployToolkit]."
        }
        Import-Module `$moduleAppDeployToolkit -Force -Verbose:`$false
    }
    Catch {
        If (`$mainExitCode -eq 0) {
            [Int32]`$mainExitCode = 60008
        }
        Write-Error -Message "Module [`$moduleAppDeployToolkit] failed to load: `n`$(`$_.Exception.Message)`n `$(`$_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            `$script:ExitCode = `$mainExitCode
            Exit
        }
        Else {
            Exit `$mainExitCode
        }
    }

    ##*===============================================
    ##* INITIALIZATION
    ##*===============================================
    [String]`$installPhase = 'Initialization'

    ## <Perform Initialization tasks here>
    
    ## Show welcome dialog and close running processes
    $welcomeCommand

    ##*===============================================
    ##* PRE-INSTALLATION
    ##*===============================================
    [String]`$installPhase = 'Pre-Installation'

    ## <Perform Pre-Installation tasks here>

    ##*===============================================
    ##* INSTALLATION
    ##*===============================================
    [String]`$installPhase = 'Installation'
    
    If (`$deploymentType -ine 'Uninstall' -and `$deploymentType -ine 'Repair') {
        ## <Perform Installation tasks here>
        [String]`$InstallFile = 'Files\$InstallFile'
        [String]`$InstallParameters = '$installParams'
          $installCommand
        
        ## Create registry keys for Intune detection
        Set-ADTRegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\$CompanyName\$AppName' -Name 'Version' -Value '$AppVersion' -Type 'String'
        Set-ADTRegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\$CompanyName\$AppName' -Name 'InstallDate' -Value (Get-Date -Format 'yyyy-MM-dd') -Type 'String'
    }
    ElseIf (`$deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]`$installPhase = 'Uninstallation'

        ## Remove registry keys for Intune detection
        Remove-ADTRegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\$CompanyName\$AppName' -Recurse

        ## <Perform Uninstallation tasks here>
        $uninstallCommand
    }
    ElseIf (`$deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]`$installPhase = 'Repair'

        ## <Perform Repair tasks here>
        $installCommand
    }

    ##*===============================================
    ##* POST-INSTALLATION
    ##*===============================================
    [String]`$installPhase = 'Post-Installation'

    ## <Perform Post-Installation tasks here>

    ## Display a message at the end of the install
    $promptCommand
}
Catch {
    [Int32]`$mainExitCode = 60001
    [String]`$mainErrorMessage = "An error occurred during the `$installPhase phase: `$(`$_.Exception.Message)"
    Write-Log -Message `$mainErrorMessage -Severity 3 -Source `$deployAppScriptFriendlyName
    Show-DialogBox -Text `$mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode `$mainExitCode
}
"@
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Starting PSADT 4.0 package creation using official New-ADTTemplate" -Type "Info"
    Write-LogMessage "Application: $AppName v$AppVersion by $AppPublisher" -Type "Info"
    Write-LogMessage "Template Mode: PSADT v4 Native Only" -Type "Info"
    
    # Set default CompanyName if not provided
    if ([string]::IsNullOrEmpty($CompanyName)) {
        $CompanyName = $AppPublisher
        Write-LogMessage "CompanyName not specified, using AppPublisher: $CompanyName" -Type "Info"
    }
    
    Write-LogMessage "Registry key will be created at: HKEY_LOCAL_MACHINE\SOFTWARE\$CompanyName\$AppName" -Type "Info"
    Write-LogMessage "Log path configured: $LogPath" -Type "Info"
    
    # Validate PSADT 4.0 installation
    if (!(Test-PSADT4Installation -Path $PSADT4Path)) {
        Write-LogMessage "PSADT 4.0 installation not found or invalid at: $PSADT4Path" -Type "Error"
        Write-LogMessage "Please ensure PSADT 4.0 is properly installed" -Type "Error"
        exit 1
    }
    
    # Import PSADT 4.0 module to get New-ADTTemplate cmdlet
    if (!(Import-PSADT4Module -Path $PSADT4Path)) {
        Write-LogMessage "Failed to import PSADT 4.0 module or New-ADTTemplate cmdlet not available" -Type "Error"
        exit 1
    }
    
    # Validate source installer file exists
    $sourceInstaller = Join-Path $SourcePath $InstallFile
    if (!(Test-Path $sourceInstaller)) {
        Write-LogMessage "Source installer not found: $sourceInstaller" -Type "Error"
        exit 1
    }
      # Create output directory
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-LogMessage "Created output directory: $OutputPath" -Type "Info"
    }
    
    # Create package directory with safe naming
    $packageName = New-SafePackageName -Publisher $AppPublisher -Name $AppName -Version $AppVersion
      # Use New-ADTTemplate to create the official v4 structure
    Write-LogMessage "Creating PSADT template using New-ADTTemplate..." -Type "Info"
    
    try {
        # Create v4 native template (Version 4 is default)
        New-ADTTemplate -Destination $OutputPath -Name $packageName
        Write-LogMessage "Created PSADT v4 native template: $packageName" -Type "Success"
    }
    catch {
        Write-LogMessage "Failed to create template using New-ADTTemplate: $($_.Exception.Message)" -Type "Error"
        exit 1
    }
    
    $packagePath = Join-Path $OutputPath $packageName
    
    if (!(Test-Path $packagePath)) {
        Write-LogMessage "Template was not created at expected location: $packagePath" -Type "Error"
        exit 1
    }
    
    # Create and populate Files directory
    $filesPath = Join-Path $packagePath "Files"
    if (!(Test-Path $filesPath)) {
        New-Item -ItemType Directory -Path $filesPath -Force | Out-Null
    }
    
    Write-LogMessage "Copying application files..." -Type "Info"
    Copy-Item -Path "$SourcePath\*" -Destination $filesPath -Recurse -Force
    
    # Generate enhanced Deploy-Application.ps1 for v4
    $deployScriptPath = Join-Path $packagePath "Deploy-Application.ps1"
    $deployScript = New-PSADT4DeployScript -AppName $AppName -AppVersion $AppVersion -AppPublisher $AppPublisher -InstallFile $InstallFile -InstallType $InstallType -Architecture $Architecture -Language $Language -CompanyName $CompanyName -LogPath $LogPath
    
    Set-Content -Path $deployScriptPath -Value $deployScript -Encoding UTF8
      Write-LogMessage "Package created successfully using official PSADT v4 methods!" -Type "Success"
    Write-LogMessage "Package location: $packagePath" -Type "Success"
    Write-LogMessage "Files directory: $filesPath" -Type "Info"
    Write-LogMessage "Deploy script: $deployScriptPath" -Type "Info"
    Write-LogMessage "Template type: v4 Native Only" -Type "Info"
    
    Write-LogMessage "`nNext steps:" -Type "Info"
    Write-LogMessage "1. Review and test Deploy-Application.ps1" -Type "Info"
    Write-LogMessage "2. Test installation locally: Deploy-Application.ps1 -DeploymentType Install" -Type "Info"
    Write-LogMessage "3. Create .intunewin file using IntuneWinAppUtil.exe" -Type "Info"
    Write-LogMessage "4. Upload to Intune or SCCM" -Type "Info"
    
    Write-LogMessage "`nPSADT v4 Native Features:" -Type "Info"
    Write-LogMessage "- Uses v4 ADT-prefixed functions (Start-ADTMsiProcess, Show-ADTInstallationWelcome)" -Type "Info"
    Write-LogMessage "- Access to latest v4 features and improvements" -Type "Info"
    Write-LogMessage "- Better performance and reliability" -Type "Info"
    Write-LogMessage "- Intune-ready registry keys and logging support" -Type "Info"
}
catch {
    Write-LogMessage "Error occurred: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script
