#Requires -Version 5.1
<#
.SYNOPSIS
    Batch processes multiple applications for PSADT 4.0 package creation

.DESCRIPTION
    Automates the creation of multiple PSADT 4.0 packages from a CSV or JSON configuration file.
    Supports parallel processing and detailed logging for enterprise environments.

.PARAMETER ConfigFile
    Path to CSV or JSON configuration file containing application details

.PARAMETER OutputPath
    Output directory for all packages (default: C:\PSADT_Packages)

.PARAMETER PSADT4Path
    Path to PSADT 4.0 installation (default: C:\PSADT4)

.PARAMETER MaxConcurrentJobs
    Maximum number of concurrent packaging jobs (default: 3)

.PARAMETER LogPath
    Path for detailed logs (default: C:\PSADT_Logs)

.PARAMETER CreateSampleConfig
    Creates a sample configuration file and exits

.EXAMPLE
    .\Batch-PSADT4Packages.ps1 -ConfigFile "C:\Config\AppList.csv"

.EXAMPLE
    .\Batch-PSADT4Packages.ps1 -ConfigFile "C:\Config\Apps.json" -MaxConcurrentJobs 5

.EXAMPLE
    .\Batch-PSADT4Packages.ps1 -CreateSampleConfig

.NOTES
    Author: IT Department
    Version: 1.0.0
    Date: 2025-06-14
    Requires: PowerShell 5.1+, PSADT 4.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if ($_ -and -not (Test-Path $_)) {
            throw "Configuration file not found: $_"
        }
        return $true
    })]
    [string]$ConfigFile,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = "C:\PSADT_Packages",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$PSADT4Path = "C:\PSADT4",
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxConcurrentJobs = 3,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = "C:\PSADT_Logs",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateSampleConfig
)

#region Helper Functions
function Write-LogMessage {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Type = "Info",
        [string]$LogFile = $null
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
    }
    
    Write-Host $logEntry -ForegroundColor $colors[$Type]
    
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
    }
}

function New-SampleConfiguration {
    param([string]$OutputPath)
    
    # Create sample CSV
    $csvPath = Join-Path $OutputPath "SampleApps.csv"
    $csvContent = @"
AppName,AppVersion,AppPublisher,SourcePath,InstallFile,InstallType,Architecture,Language
Adobe Acrobat Reader,24.002.20933,Adobe,C:\Source\Adobe,AdobeReader.exe,EXE,x64,EN
7-Zip,23.01,Igor Pavlov,C:\Source\7Zip,7z2301-x64.msi,MSI,x64,EN
Notepad++,8.5.8,Don Ho,C:\Source\NotepadPlusPlus,npp.8.5.8.Installer.x64.exe,EXE,x64,EN
Microsoft Visual C++ 2022 Redistributable,14.40.33810,Microsoft,C:\Source\VCRedist,VC_redist.x64.exe,EXE,x64,EN
"@
    
    Set-Content -Path $csvPath -Value $csvContent -Encoding UTF8
    
    # Create sample JSON
    $jsonPath = Join-Path $OutputPath "SampleApps.json"
    $jsonContent = @{
        "metadata" = @{
            "version" = "1.0"
            "created" = (Get-Date -Format "yyyy-MM-dd")
            "description" = "PSADT 4.0 Application Configuration"
        }
        "defaults" = @{
            "architecture" = "x64"
            "language" = "EN"
            "outputPath" = "C:\PSADT_Packages"
        }
        "applications" = @(
            @{
                "appName" = "Adobe Acrobat Reader"
                "appVersion" = "24.002.20933"
                "appPublisher" = "Adobe"
                "sourcePath" = "C:\Source\Adobe"
                "installFile" = "AdobeReader.exe"
                "installType" = "EXE"
                "architecture" = "x64"
                "language" = "EN"
                "priority" = 1
                "enabled" = $true
            },
            @{
                "appName" = "7-Zip"
                "appVersion" = "23.01"
                "appPublisher" = "Igor Pavlov"
                "sourcePath" = "C:\Source\7Zip"
                "installFile" = "7z2301-x64.msi"
                "installType" = "MSI"
                "architecture" = "x64"
                "language" = "EN"
                "priority" = 2
                "enabled" = $true
            }
        )
    } | ConvertTo-Json -Depth 4
    
    Set-Content -Path $jsonPath -Value $jsonContent -Encoding UTF8
    
    return @($csvPath, $jsonPath)
}

function Import-ApplicationConfiguration {
    param([string]$ConfigFile)
    
    $extension = [System.IO.Path]::GetExtension($ConfigFile).ToLower()
    
    switch ($extension) {
        ".csv" {
            $apps = Import-Csv -Path $ConfigFile
            return $apps | ForEach-Object {
                @{
                    AppName = $_.AppName
                    AppVersion = $_.AppVersion
                    AppPublisher = $_.AppPublisher
                    SourcePath = $_.SourcePath
                    InstallFile = $_.InstallFile
                    InstallType = $_.InstallType
                    Architecture = if ($_.Architecture) { $_.Architecture } else { "x64" }
                    Language = if ($_.Language) { $_.Language } else { "EN" }
                    Enabled = if ($_.Enabled) { [bool]::Parse($_.Enabled) } else { $true }
                }
            }
        }
        ".json" {
            $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            return $config.applications | Where-Object { $_.enabled -eq $true } | ForEach-Object {
                @{
                    AppName = $_.appName
                    AppVersion = $_.appVersion
                    AppPublisher = $_.appPublisher
                    SourcePath = $_.sourcePath
                    InstallFile = $_.installFile
                    InstallType = $_.installType
                    Architecture = if ($_.architecture) { $_.architecture } else { $config.defaults.architecture }
                    Language = if ($_.language) { $_.language } else { $config.defaults.language }
                    Enabled = $_.enabled
                }
            }
        }
        default {
            throw "Unsupported configuration file format: $extension. Use .csv or .json"
        }
    }
}

function Test-ApplicationConfiguration {
    param([object[]]$Applications)
    
    $errors = @()
    
    foreach ($app in $Applications) {
        # Required fields validation
        $requiredFields = @('AppName', 'AppVersion', 'AppPublisher', 'SourcePath', 'InstallFile', 'InstallType')
        
        foreach ($field in $requiredFields) {
            if (-not $app.$field -or [string]::IsNullOrWhiteSpace($app.$field)) {
                $errors += "Application '$($app.AppName)': Missing required field '$field'"
            }
        }
        
        # Validate source path exists
        if ($app.SourcePath -and -not (Test-Path $app.SourcePath)) {
            $errors += "Application '$($app.AppName)': Source path not found: $($app.SourcePath)"
        }
        
        # Validate installer file exists
        if ($app.SourcePath -and $app.InstallFile) {
            $installerPath = Join-Path $app.SourcePath $app.InstallFile
            if (-not (Test-Path $installerPath)) {
                $errors += "Application '$($app.AppName)': Installer file not found: $installerPath"
            }
        }
        
        # Validate install type
        if ($app.InstallType -and $app.InstallType -notin @('MSI', 'EXE', 'MSP')) {
            $errors += "Application '$($app.AppName)': Invalid install type: $($app.InstallType)"
        }
        
        # Validate architecture
        if ($app.Architecture -and $app.Architecture -notin @('x86', 'x64', 'ARM64')) {
            $errors += "Application '$($app.AppName)': Invalid architecture: $($app.Architecture)"
        }
    }
    
    return $errors
}

function Start-PackageCreation {
    param(
        [object]$App,
        [string]$OutputPath,
        [string]$PSADT4Path,
        [string]$LogFile
    )
    
    $scriptPath = Join-Path $PSScriptRoot "New-PSADT4Package.ps1"
    
    $arguments = @(
        "-AppName", "`"$($App.AppName)`""
        "-AppVersion", "`"$($App.AppVersion)`""
        "-AppPublisher", "`"$($App.AppPublisher)`""
        "-SourcePath", "`"$($App.SourcePath)`""
        "-InstallFile", "`"$($App.InstallFile)`""
        "-InstallType", $App.InstallType
        "-OutputPath", "`"$OutputPath`""
        "-PSADT4Path", "`"$PSADT4Path`""
        "-Architecture", $App.Architecture
        "-Language", $App.Language
    )
    
    return Start-Job -ScriptBlock {
        param($ScriptPath, $Arguments, $LogFile)
        
        try {
            $result = & $ScriptPath @Arguments 2>&1
            return @{
                Success = $true
                Output = $result
                Error = $null
            }
        }
        catch {
            return @{
                Success = $false
                Output = $null
                Error = $_.Exception.Message
            }
        }
    } -ArgumentList $scriptPath, $arguments, $LogFile
}
#endregion Helper Functions

#region Main Script
try {
    # Create sample configuration if requested
    if ($CreateSampleConfig) {
        $samplePath = Join-Path (Get-Location) "SampleConfigs"
        if (!(Test-Path $samplePath)) {
            New-Item -ItemType Directory -Path $samplePath -Force | Out-Null
        }
        
        $samples = New-SampleConfiguration -OutputPath $samplePath
        Write-LogMessage "Sample configuration files created:" -Type "Success"
        foreach ($sample in $samples) {
            Write-LogMessage "  $sample" -Type "Info"
        }
        exit 0
    }
    
    # Validate required parameters
    if (-not $ConfigFile) {
        Write-LogMessage "ConfigFile parameter is required. Use -CreateSampleConfig to generate sample files." -Type "Error"
        exit 1
    }
    
    # Setup logging
    if (!(Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = Join-Path $LogPath "BatchPackaging-$timestamp.log"
    
    Write-LogMessage "Starting batch PSADT 4.0 package creation" -Type "Info" -LogFile $logFile
    Write-LogMessage "Configuration file: $ConfigFile" -Type "Info" -LogFile $logFile
    Write-LogMessage "Output path: $OutputPath" -Type "Info" -LogFile $logFile
    Write-LogMessage "Log file: $logFile" -Type "Info" -LogFile $logFile
    
    # Validate PSADT 4.0 installation
    if (!(Test-Path (Join-Path $PSADT4Path "Toolkit\AppDeployToolkit\AppDeployToolkitMain.ps1"))) {
        Write-LogMessage "PSADT 4.0 not found at: $PSADT4Path" -Type "Error" -LogFile $logFile
        Write-LogMessage "Please run Setup-PSADT4.ps1 first" -Type "Error" -LogFile $logFile
        exit 1
    }
    
    # Load and validate configuration
    Write-LogMessage "Loading application configuration..." -Type "Info" -LogFile $logFile
    $applications = Import-ApplicationConfiguration -ConfigFile $ConfigFile
    
    Write-LogMessage "Found $($applications.Count) applications in configuration" -Type "Info" -LogFile $logFile
    
    # Validate configuration
    $validationErrors = Test-ApplicationConfiguration -Applications $applications
    if ($validationErrors.Count -gt 0) {
        Write-LogMessage "Configuration validation failed:" -Type "Error" -LogFile $logFile
        foreach ($error in $validationErrors) {
            Write-LogMessage "  $error" -Type "Error" -LogFile $logFile
        }
        exit 1
    }
    
    # Create output directory
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-LogMessage "Created output directory: $OutputPath" -Type "Info" -LogFile $logFile
    }
    
    # Process applications with job management
    $jobs = @()
    $completed = @()
    $failed = @()
    
    Write-LogMessage "Starting package creation with max $MaxConcurrentJobs concurrent jobs..." -Type "Info" -LogFile $logFile
    
    foreach ($app in $applications) {
        # Wait for available job slot
        while ($jobs.Count -ge $MaxConcurrentJobs) {
            $completedJobs = $jobs | Where-Object { $_.State -eq 'Completed' }
            
            foreach ($job in $completedJobs) {
                $result = Receive-Job -Job $job
                $appName = $job.Name
                
                if ($result.Success) {
                    $completed += $appName
                    Write-LogMessage "✓ Completed: $appName" -Type "Success" -LogFile $logFile
                } else {
                    $failed += @{ Name = $appName; Error = $result.Error }
                    Write-LogMessage "✗ Failed: $appName - $($result.Error)" -Type "Error" -LogFile $logFile
                }
                
                Remove-Job -Job $job
                $jobs = $jobs | Where-Object { $_.Id -ne $job.Id }
            }
            
            if ($jobs.Count -ge $MaxConcurrentJobs) {
                Start-Sleep -Seconds 2
            }
        }
        
        # Start new job
        Write-LogMessage "Starting: $($app.AppName) v$($app.AppVersion)" -Type "Info" -LogFile $logFile
        $job = Start-PackageCreation -App $app -OutputPath $OutputPath -PSADT4Path $PSADT4Path -LogFile $logFile
        $job.Name = "$($app.AppPublisher)-$($app.AppName)-$($app.AppVersion)"
        $jobs += $job
    }
    
    # Wait for remaining jobs to complete
    Write-LogMessage "Waiting for remaining jobs to complete..." -Type "Info" -LogFile $logFile
    
    while ($jobs.Count -gt 0) {
        $completedJobs = $jobs | Where-Object { $_.State -eq 'Completed' }
        
        foreach ($job in $completedJobs) {
            $result = Receive-Job -Job $job
            $appName = $job.Name
            
            if ($result.Success) {
                $completed += $appName
                Write-LogMessage "✓ Completed: $appName" -Type "Success" -LogFile $logFile
            } else {
                $failed += @{ Name = $appName; Error = $result.Error }
                Write-LogMessage "✗ Failed: $appName - $($result.Error)" -Type "Error" -LogFile $logFile
            }
            
            Remove-Job -Job $job
            $jobs = $jobs | Where-Object { $_.Id -ne $job.Id }
        }
        
        if ($jobs.Count -gt 0) {
            Start-Sleep -Seconds 2
        }
    }
    
    # Summary report
    Write-LogMessage "`n=== BATCH PROCESSING SUMMARY ===" -Type "Info" -LogFile $logFile
    Write-LogMessage "Total applications: $($applications.Count)" -Type "Info" -LogFile $logFile
    Write-LogMessage "Successfully completed: $($completed.Count)" -Type "Success" -LogFile $logFile
    Write-LogMessage "Failed: $($failed.Count)" -Type "$(if ($failed.Count -gt 0) { 'Error' } else { 'Info' })" -LogFile $logFile
    
    if ($completed.Count -gt 0) {
        Write-LogMessage "`nSuccessful packages:" -Type "Success" -LogFile $logFile
        foreach ($app in $completed) {
            Write-LogMessage "  ✓ $app" -Type "Success" -LogFile $logFile
        }
    }
    
    if ($failed.Count -gt 0) {
        Write-LogMessage "`nFailed packages:" -Type "Error" -LogFile $logFile
        foreach ($app in $failed) {
            Write-LogMessage "  ✗ $($app.Name): $($app.Error)" -Type "Error" -LogFile $logFile
        }
    }
    
    Write-LogMessage "`nPackages location: $OutputPath" -Type "Info" -LogFile $logFile
    Write-LogMessage "Detailed log: $logFile" -Type "Info" -LogFile $logFile
    
    if ($failed.Count -eq 0) {
        Write-LogMessage "All packages created successfully!" -Type "Success" -LogFile $logFile
    }
}
catch {
    Write-LogMessage "Batch processing failed: $($_.Exception.Message)" -Type "Error" -LogFile $logFile
    exit 1
}
#endregion Main Script
