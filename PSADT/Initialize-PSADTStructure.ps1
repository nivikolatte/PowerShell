#Requires -Version 5.1

param(
    [string]$BasePath = "C:\PSADT_Automation"
)

function Write-LogMessage {
    param([string]$Message, [string]$Type = "Info")
    
    $colors = @{ Info = "White"; Warning = "Yellow"; Error = "Red"; Success = "Green" }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Type]
}

function Install-PSADT4Module {
    param([string]$BasePath)
    
    Write-LogMessage "Installing PSADT v4 module..." -Type "Info"
    
    try {
        # Check if module is already installed
        $existingModule = Get-Module -ListAvailable -Name PSAppDeployToolkit -ErrorAction SilentlyContinue
        
        if ($existingModule) {
            Write-LogMessage "PSAppDeployToolkit module already installed (Version: $($existingModule.Version))" -Type "Success"
            return $true
        }
        
        # Install from PowerShell Gallery
        Write-LogMessage "Installing PSAppDeployToolkit module from PowerShell Gallery..." -Type "Info"
        Install-Module -Name PSAppDeployToolkit -Scope CurrentUser -Force -AllowClobber
        
        # Verify installation
        $installedModule = Get-Module -ListAvailable -Name PSAppDeployToolkit -ErrorAction SilentlyContinue
        if ($installedModule) {
            Write-LogMessage "Module installation verified (Version: $($installedModule.Version))" -Type "Success"
            return $true
        } else {
            Write-LogMessage "Module installation verification failed" -Type "Error"
            return $false
        }
    }
    catch {
        Write-LogMessage "Failed to install PSADT v4 module: $($_.Exception.Message)" -Type "Error"
        return $false
    }
}

try {
    Write-LogMessage "Initializing PSADT 4.0 Automation Structure" -Type "Info"
    Write-LogMessage "Base Path: $BasePath" -Type "Info"
    
    # Create directories
    $directories = @("Scripts", "PSADT4", "Source", "Packages", "Logs", "Reports", "Documentation")
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $BasePath $dir
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-LogMessage "Created: $dir" -Type "Success"
        } else {
            Write-LogMessage "Exists: $dir" -Type "Info"
        }
    }
    
    # Copy scripts
    $scriptsPath = Join-Path $BasePath "Scripts"
    $scriptFiles = @("New-PSADT4Package.ps1", "Setup-PSADT4.ps1", "Test-PSADT4Package.ps1")
    
    foreach ($script in $scriptFiles) {
        $sourcePath = Join-Path $PSScriptRoot $script
        $destPath = Join-Path $scriptsPath $script
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-LogMessage "Copied: $script" -Type "Success"
        }
    }
    
    # Install PSADT module
    $moduleInstalled = Install-PSADT4Module -BasePath $BasePath
    
    Write-LogMessage "`n=== SETUP COMPLETE ===" -Type "Success"
    Write-LogMessage "PSADT 4.0 Automation structure created at: $BasePath" -Type "Success"
    
    if ($moduleInstalled) {
        Write-LogMessage "PSADT v4 module is ready!" -Type "Success"
    } else {
        Write-LogMessage "Manual installation needed: Install-Module PSAppDeployToolkit" -Type "Warning"
    }
    
    Write-LogMessage "`nQuick Test Commands:" -Type "Info"
    Write-LogMessage "cd '$BasePath'" -Type "Info"
    Write-LogMessage "Import-Module PSAppDeployToolkit" -Type "Info"
    Write-LogMessage "Get-Command New-ADTTemplate" -Type "Info"
}
catch {
    Write-LogMessage "Setup failed: $($_.Exception.Message)" -Type "Error"
    exit 1
}
