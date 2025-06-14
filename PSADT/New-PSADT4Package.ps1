#Requires -Version 5.1
<#
.SYNOPSIS
    Creates PSADT 4.0 packages with modern best practices and automation

.DESCRIPTION
    Automates the creation of PowerShell App Deployment Toolkit 4.0 packages by:
    - Setting up proper PSADT 4.0 directory structure
    - Generating compliant Deploy-Application.ps1 scripts
    - Following PSADT 4.0 documentation standards
    - Supporting MSI, EXE, and MSP installer types

.PARAMETER AppName
    Name of the application (e.g., "Adobe Acrobat Reader")

.PARAMETER AppVersion
    Version of the application (e.g., "24.002.20933")

.PARAMETER AppPublisher
    Publisher/vendor of the application (e.g., "Adobe")

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

.PARAMETER Architecture
    Target architecture: x86, x64, or ARM64 (default: x64)

.PARAMETER Language
    Application language code (default: EN)

.EXAMPLE
    .\New-PSADT4Package.ps1 -AppName "Adobe Acrobat Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -SourcePath "C:\Source\Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE"

.EXAMPLE
    .\New-PSADT4Package.ps1 -AppName "7-Zip" -AppVersion "23.01" -AppPublisher "Igor Pavlov" -SourcePath "C:\Source\7Zip" -InstallFile "7z2301-x64.msi" -InstallType "MSI"

.NOTES
    Author: IT Department
    Version: 2.0.0
    Date: 2025-06-14
    Requires: PowerShell 5.1+, PSADT 4.0
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
    
    $requiredFiles = @(
        "Toolkit\Deploy-Application.ps1",
        "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1",
        "Toolkit\AppDeployToolkit\AppDeployToolkitExtensions.ps1"
    )
    
    foreach ($file in $requiredFiles) {
        if (!(Test-Path (Join-Path $Path $file))) {
            return $false
        }
    }
    
    # Check for PSADT 4.0 version
    $mainScript = Join-Path $Path "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"
    $content = Get-Content $mainScript -Raw -ErrorAction SilentlyContinue
    
    if ($content -match "Version.*4\." -or $content -match "PSAppDeployToolkit.*4") {
        return $true
    }
    
    return $false
}

function New-SafePackageName {
    param(
        [string]$Publisher,
        [string]$Name,
        [string]$Version
    )
    
    # Remove invalid characters and create safe package name
    $safeName = "$Publisher-$Name-$Version" -replace '[^\w\.-]', ''
    return $safeName
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Starting PSADT 4.0 package creation for $AppName v$AppVersion" -Type "Info"
    
    # Validate PSADT 4.0 installation
    if (!(Test-PSADT4Installation -Path $PSADT4Path)) {
        Write-LogMessage "PSADT 4.0 installation not found or invalid at: $PSADT4Path" -Type "Error"
        Write-LogMessage "Please ensure PSADT 4.0 is properly installed" -Type "Error"
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
    $packagePath = Join-Path $OutputPath $packageName
    
    if (Test-Path $packagePath) {
        Write-LogMessage "Removing existing package directory: $packagePath" -Type "Warning"
        Remove-Item $packagePath -Recurse -Force
    }
    
    Write-LogMessage "Creating package: $packageName" -Type "Info"
    New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    
    # Copy PSADT 4.0 toolkit
    $toolkitSource = Join-Path $PSADT4Path "Toolkit"
    Write-LogMessage "Copying PSADT 4.0 toolkit files..." -Type "Info"
    Copy-Item -Path "$toolkitSource\*" -Destination $packagePath -Recurse -Force
    
    # Create and populate Files directory
    $filesPath = Join-Path $packagePath "Files"
    New-Item -ItemType Directory -Path $filesPath -Force | Out-Null
    
    Write-LogMessage "Copying application files..." -Type "Info"
    Copy-Item -Path "$SourcePath\*" -Destination $filesPath -Recurse -Force
    
    # Generate PSADT 4.0 compliant Deploy-Application.ps1
    $deployScriptPath = Join-Path $packagePath "Deploy-Application.ps1"
    $deployScript = New-PSADT4DeployScript -AppName $AppName -AppVersion $AppVersion -AppPublisher $AppPublisher -InstallFile $InstallFile -InstallType $InstallType -Architecture $Architecture -Language $Language
    
    Set-Content -Path $deployScriptPath -Value $deployScript -Encoding UTF8
    
    Write-LogMessage "Package created successfully!" -Type "Success"
    Write-LogMessage "Package location: $packagePath" -Type "Success"
    Write-LogMessage "Files directory: $filesPath" -Type "Info"
    Write-LogMessage "Deploy script: $deployScriptPath" -Type "Info"
    
    Write-LogMessage "`nNext steps:" -Type "Info"
    Write-LogMessage "1. Review and test Deploy-Application.ps1" -Type "Info"
    Write-LogMessage "2. Test installation locally: Deploy-Application.ps1 -DeploymentType Install" -Type "Info"
    Write-LogMessage "3. Create .intunewin file using IntuneWinAppUtil.exe" -Type "Info"
    Write-LogMessage "4. Upload to Intune or SCCM" -Type "Info"
}
catch {
    Write-LogMessage "Error occurred: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script

#region Deploy Script Generator
function New-PSADT4DeployScript {
    param(
        [string]$AppName,
        [string]$AppVersion,
        [string]$AppPublisher,
        [string]$InstallFile,
        [string]$InstallType,
        [string]$Architecture,
        [string]$Language
    )
    
    $processName = ($AppName -replace '\s+', '') -replace '[^\w]', ''
    $currentDate = Get-Date -Format "MM/dd/yyyy"
    
    # Generate install parameters based on type
    $installParams = switch ($InstallType) {
        "MSI" { "ALLUSERS=1 REBOOT=ReallySuppress /quiet" }
        "EXE" { "/S /v/qn" }
        "MSP" { "/quiet /norestart" }
    }
    
    # Generate install command based on type
    $installCommand = switch ($InstallType) {
        "MSI" { 
            "Execute-MSI -Action 'Install' -Path `$InstallFile -Parameters `$InstallParameters"
        }
        "EXE" { 
            "Execute-Process -Path `$InstallFile -Parameters `$InstallParameters -WindowStyle 'Hidden' -IgnoreExitCodes '3010'"
        }
        "MSP" { 
            "Execute-MSI -Action 'Patch' -Path `$InstallFile -Parameters `$InstallParameters"
        }
    }
    
    # Generate uninstall command based on type
    $uninstallCommand = switch ($InstallType) {
        "MSI" { 
            "Execute-MSI -Action 'Uninstall' -Path `$InstallFile"
        }
        "EXE" { 
            "# Define uninstall method for EXE installer`n        Write-Log -Message 'Custom uninstall logic required for EXE installer' -Severity 2"
        }
        "MSP" { 
            "# MSP patches typically don't have standalone uninstall`n        Write-Log -Message 'MSP patch uninstall requires base application removal' -Severity 2"
        }
    }

    return @"
#Requires -Version 5.1
<#
.SYNOPSIS
    $AppName v$AppVersion Deployment Script
.DESCRIPTION
    Deploys $AppName using PowerShell App Deployment Toolkit 4.0
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
    [Version]`$deployAppScriptVersion = [Version]'3.10.2'
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

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]`$moduleAppDeployToolkitMain = "`$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath `$moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [`$moduleAppDeployToolkitMain]."
        }
        If (`$DisableLogging) {
            . `$moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . `$moduleAppDeployToolkitMain
        }
    }
    Catch {
        If (`$mainExitCode -eq 0) {
            [Int32]`$mainExitCode = 60008
        }
        Write-Error -Message "Module [`$moduleAppDeployToolkitMain] failed to load: `n`$(`$_.Exception.Message)`n `$(`$_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            `$script:ExitCode = `$mainExitCode; Exit
        }
        Else {
            Exit `$mainExitCode
        }
    }

    ## Variables: Installer Files
    [String]`$InstallFile = '$InstallFile'
    [String]`$InstallParameters = '$installParams'
    #endregion Initialization

    ##*===============================================
    ##* PRE-INSTALLATION
    ##*===============================================
    [String]`$installPhase = 'Pre-Installation'

    ## Show Welcome Message, close applications if required, verify there is enough disk space to complete the install, and persist the prompt
    Show-InstallationWelcome -CloseApps '$processName' -CheckDiskSpace -PersistPrompt

    ## Show Progress Message (with the default message)
    Show-InstallationProgress

    ## <Perform Pre-Installation tasks here>

    ##*===============================================
    ##* INSTALLATION
    ##*===============================================
    [String]`$installPhase = 'Installation'

    If (`$deploymentType -ine 'Uninstall' -and `$deploymentType -ine 'Repair') {
        ## Handle Zero-Config MSI Installations
        If (`$useDefaultMsi) {
            [Hashtable]`$ExecuteDefaultMSISplat = @{
                Action = 'Install'
                Path = `$defaultMsiFile
            }
            If (`$defaultMstFile) {
                `$ExecuteDefaultMSISplat.Add('Transform', `$defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        Else {
            ## <Perform Installation tasks here>
            $installCommand
        }

        ## <Perform Post-Installation tasks here>
    }
    ElseIf (`$deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]`$installPhase = 'Uninstallation'

        ## Handle Zero-Config MSI Uninstallations
        If (`$useDefaultMsi) {
            [Hashtable]`$ExecuteDefaultMSISplat = @{
                Action = 'Uninstall'
                Path = `$defaultMsiFile
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        Else {
            ## <Perform Uninstallation tasks here>
            $uninstallCommand
        }
    }
    ElseIf (`$deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]`$installPhase = 'Repair'

        ## Handle Zero-Config MSI Repairs
        If (`$useDefaultMsi) {
            [Hashtable]`$ExecuteDefaultMSISplat = @{
                Action = 'Repair'
                Path = `$defaultMsiFile
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        Else {
            ## <Perform Repair tasks here>
            Execute-MSI -Action 'Repair' -Path `$InstallFile -Parameters `$InstallParameters
        }
    }

    ##*===============================================
    ##* POST-INSTALLATION
    ##*===============================================
    [String]`$installPhase = 'Post-Installation'

    ## <Perform Post-Installation tasks here>

    ## Display a message at the end of the install
    If (-not `$useDefaultMsi) {
        Show-InstallationPrompt -Message "`$installTitle installation completed successfully." -ButtonRightText 'OK' -Icon Information -NoWait
    }
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
#endregion Deploy Script Generator
