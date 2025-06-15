#Requires -Version 5.1
<#
.SYNOPSIS
    Tests PowerShell App Deployment Toolkit 4.0 packages created with official New-ADTTemplate

.DESCRIPTION
    This script validates PSADT 4.0 packages created using New-ADTTemplate, ensuring they
    conform to official v4 structure and best practices. It tests both v4 native and
    v3 compatibility templates, validates Deploy-Application.ps1 syntax, and verifies
    proper module import capabilities.
    
    Validation includes:
    - Official v4 template structure verification
    - v4 vs v3 compatibility mode detection
    - ADT-prefixed function usage validation
    - Module import and session management testing
    - Deploy-Application.ps1 syntax verification

.PARAMETER PackagePath
    Path to the PSADT 4.0 package to test

.PARAMETER TestV3Compatibility
    Test v3 compatibility mode features specifically

.PARAMETER SkipSyntaxCheck
    Skip PowerShell syntax validation

.PARAMETER OutputReport
    Generate detailed validation report

.PARAMETER ReportPath
    Path for validation reports (default: C:\PSADT_Reports)

.EXAMPLE
    .\Test-PSADT4Package-Official.ps1 -PackagePath "C:\PSADT_Packages\VideoLAN-VLC_Media_Player-3.0.20"

.EXAMPLE
    .\Test-PSADT4Package-Official.ps1 -PackagePath "C:\PSADT_Packages\MyApp" -TestV3Compatibility -OutputReport

.NOTES
    Author: IT Department
    Version: 3.0.0
    Date: 2025-01-15
    Requires: PowerShell 5.1+, PSADT 4.0 with New-ADTTemplate
    Updated: Enhanced for official New-ADTTemplate created packages
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to PSADT package")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$PackagePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestV3Compatibility,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSyntaxCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$OutputReport,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ReportPath = "C:\PSADT_Reports"
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

function Test-PSADT4Structure {
    param(
        [string]$Path,
        [ref]$Results
    )
    
    Write-LogMessage "Testing PSADT 4.0 structure..." -Type "Info"
    
    # Required files for PSADT 4.0 packages
    $requiredFiles = @(
        "Deploy-Application.ps1",
        "PSAppDeployToolkit.psm1",
        "PSAppDeployToolkit.psd1"
    )
    
    $structureValid = $true
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $Path $file
        if (Test-Path $filePath) {
            Write-LogMessage "✓ Found: $file" -Type "Success"
        } else {
            Write-LogMessage "✗ Missing: $file" -Type "Error"
            $structureValid = $false
            $missingFiles += $file
        }
    }
    
    # Check for Files directory
    $filesPath = Join-Path $Path "Files"
    if (Test-Path $filesPath) {
        Write-LogMessage "✓ Found: Files directory" -Type "Success"
    } else {
        Write-LogMessage "✗ Missing: Files directory" -Type "Warning"
    }
    
    # Check for v4 module manifest version
    $manifestPath = Join-Path $Path "PSAppDeployToolkit.psd1"
    if (Test-Path $manifestPath) {
        try {
            $manifest = Import-PowerShellDataFile $manifestPath -ErrorAction Stop
            $version = [Version]$manifest.ModuleVersion
            if ($version.Major -ge 4) {
                Write-LogMessage "✓ PSADT Version: $($version.ToString()) (v4 compatible)" -Type "Success"
            } else {
                Write-LogMessage "✗ PSADT Version: $($version.ToString()) (v4 required)" -Type "Error"
                $structureValid = $false
            }
        }
        catch {
            Write-LogMessage "✗ Could not validate PSADT version: $($_.Exception.Message)" -Type "Error"
            $structureValid = $false
        }
    }
    
    $Results.Value.StructureValid = $structureValid
    $Results.Value.MissingFiles = $missingFiles
    
    return $structureValid
}

function Test-DeployScript {
    param(
        [string]$Path,
        [bool]$SkipSyntax,
        [bool]$TestV3Mode,
        [ref]$Results
    )
    
    Write-LogMessage "Testing Deploy-Application.ps1..." -Type "Info"
    
    $deployScript = Join-Path $Path "Deploy-Application.ps1"
    $scriptValid = $true
    $issues = @()
    
    if (!(Test-Path $deployScript)) {
        Write-LogMessage "✗ Deploy-Application.ps1 not found" -Type "Error"
        $Results.Value.ScriptValid = $false
        return $false
    }
    
    # Read script content
    try {
        $content = Get-Content $deployScript -Raw -ErrorAction Stop
        Write-LogMessage "✓ Deploy-Application.ps1 readable" -Type "Success"
    }
    catch {
        Write-LogMessage "✗ Could not read Deploy-Application.ps1: $($_.Exception.Message)" -Type "Error"
        $Results.Value.ScriptValid = $false
        return $false
    }
    
    # Test PowerShell syntax
    if (!$SkipSyntax) {
        Write-LogMessage "Checking PowerShell syntax..." -Type "Info"
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
            Write-LogMessage "✓ PowerShell syntax valid" -Type "Success"
        }
        catch {
            Write-LogMessage "✗ PowerShell syntax error: $($_.Exception.Message)" -Type "Error"
            $scriptValid = $false
            $issues += "Syntax error: $($_.Exception.Message)"
        }
    }
    
    # Detect template type (v4 native vs v3 compatibility)
    $hasV4Functions = $false
    $hasV3Functions = $false
    
    # Check for v4 ADT-prefixed functions
    $v4Functions = @(
        'Start-ADTProcess',
        'Start-ADTMsiProcess', 
        'Show-ADTInstallationWelcome',
        'Show-ADTInstallationPrompt',
        'Open-ADTSession'
    )
    
    foreach ($func in $v4Functions) {
        if ($content -match $func) {
            $hasV4Functions = $true
            Write-LogMessage "✓ Found v4 function: $func" -Type "Success"
            break
        }
    }
    
    # Check for v3 compatibility functions
    $v3Functions = @(
        'Execute-Process',
        'Execute-MSI',
        'Show-InstallationWelcome',
        'Show-InstallationPrompt'
    )
    
    foreach ($func in $v3Functions) {
        if ($content -match $func) {
            $hasV3Functions = $true
            Write-LogMessage "✓ Found v3 compatibility function: $func" -Type "Info"
            break
        }
    }
    
    # Determine template type
    if ($hasV4Functions -and !$hasV3Functions) {
        $templateType = "v4 Native"
        Write-LogMessage "✓ Template Type: v4 Native (uses ADT-prefixed functions)" -Type "Success"
    }
    elseif ($hasV3Functions -and !$hasV4Functions) {
        $templateType = "v3 Compatibility"
        Write-LogMessage "✓ Template Type: v3 Compatibility (uses legacy function names)" -Type "Info"
    }
    elseif ($hasV4Functions -and $hasV3Functions) {
        $templateType = "Mixed"
        Write-LogMessage "⚠ Template Type: Mixed (contains both v3 and v4 functions)" -Type "Warning"
        $issues += "Mixed function usage detected - consider standardizing on one approach"
    }
    else {
        $templateType = "Unknown"
        Write-LogMessage "⚠ Template Type: Unknown (no recognizable PSADT functions found)" -Type "Warning"
        $issues += "No recognizable PSADT functions found"
    }
    
    # Test v3 compatibility mode if requested
    if ($TestV3Mode -and $templateType -ne "v3 Compatibility") {
        Write-LogMessage "⚠ TestV3Compatibility requested but template is not v3 compatible" -Type "Warning"
        $issues += "Template does not appear to use v3 compatibility mode"
    }
    
    # Check for required variable declarations
    $requiredVars = @('appVendor', 'appName', 'appVersion', 'deploymentType')
    foreach ($var in $requiredVars) {
        if ($content -match "\`$$var") {
            Write-LogMessage "✓ Found variable: `$$var" -Type "Success"
        } else {
            Write-LogMessage "⚠ Variable not found: `$$var" -Type "Warning"
            $issues += "Missing variable: `$$var"
        }
    }
    
    # Check for module import
    if ($content -match 'Import-Module.*PSAppDeployToolkit') {
        Write-LogMessage "✓ Module import found" -Type "Success"
    } else {
        Write-LogMessage "⚠ PSAppDeployToolkit module import not found" -Type "Warning"
        $issues += "Module import not found"
    }
    
    $Results.Value.ScriptValid = $scriptValid
    $Results.Value.TemplateType = $templateType
    $Results.Value.Issues = $issues
    
    return $scriptValid
}

function Test-ModuleImport {
    param(
        [string]$Path,
        [ref]$Results
    )
    
    Write-LogMessage "Testing module import capability..." -Type "Info"
    
    $modulePath = Join-Path $Path "PSAppDeployToolkit.psm1"
    $importSuccess = $false
    
    if (!(Test-Path $modulePath)) {
        Write-LogMessage "✗ PSAppDeployToolkit.psm1 not found" -Type "Error"
        $Results.Value.ModuleImportValid = $false
        return $false
    }
    
    try {
        # Test module import in isolated scope
        $job = Start-Job -ScriptBlock {
            param($ModulePath)
            try {
                Import-Module $ModulePath -Force -ErrorAction Stop
                return $true
            }
            catch {
                return $false
            }
        } -ArgumentList $modulePath
        
        $importResult = $job | Wait-Job | Receive-Job
        $job | Remove-Job -Force
        
        if ($importResult) {
            Write-LogMessage "✓ Module import test successful" -Type "Success"
            $importSuccess = $true
        } else {
            Write-LogMessage "✗ Module import test failed" -Type "Error"
        }
    }
    catch {
        Write-LogMessage "✗ Module import test error: $($_.Exception.Message)" -Type "Error"
    }
    
    $Results.Value.ModuleImportValid = $importSuccess
    return $importSuccess
}

function New-ValidationReport {
    param(
        [string]$PackagePath,
        [hashtable]$Results,
        [string]$ReportPath
    )
    
    if (!(Test-Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }
    
    $reportFile = Join-Path $ReportPath "PSADT_Validation_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    $packageName = Split-Path $PackagePath -Leaf
    
    $report = @"
# PSADT 4.0 Package Validation Report

**Package:** $packageName  
**Path:** $PackagePath  
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Template Type:** $($Results.TemplateType)

## Validation Results

### Structure Validation
- **Status:** $(if($Results.StructureValid) { '✅ PASS' } else { '❌ FAIL' })
- **Missing Files:** $($Results.MissingFiles -join ', ')

### Script Validation  
- **Status:** $(if($Results.ScriptValid) { '✅ PASS' } else { '❌ FAIL' })
- **Issues:** $($Results.Issues -join '; ')

### Module Import
- **Status:** $(if($Results.ModuleImportValid) { '✅ PASS' } else { '❌ FAIL' })

## Overall Assessment
**Result:** $(if($Results.StructureValid -and $Results.ScriptValid -and $Results.ModuleImportValid) { '✅ PACKAGE VALID' } else { '❌ PACKAGE NEEDS ATTENTION' })

## Recommendations
$( if($Results.TemplateType -eq 'v4 Native') { '- Package uses modern v4 ADT-prefixed functions ✅' } 
   elseif($Results.TemplateType -eq 'v3 Compatibility') { '- Package uses v3 compatibility mode - consider migrating to v4 native functions' }
   else { '- Template type unclear - review function usage' } )
$( if($Results.Issues.Count -gt 0) { "- Address the following issues: $($Results.Issues -join '; ')" } else { '- No issues found ✅' } )

---
*Generated by PSADT Package Validator v3.0.0*
"@
    
    Set-Content -Path $reportFile -Value $report -Encoding UTF8
    Write-LogMessage "Validation report saved: $reportFile" -Type "Success"
    
    return $reportFile
}
#endregion Helper Functions

#region Main Script
try {
    Write-LogMessage "Starting PSADT 4.0 package validation..." -Type "Info"
    Write-LogMessage "Package: $(Split-Path $PackagePath -Leaf)" -Type "Info"
    Write-LogMessage "Location: $PackagePath" -Type "Info"
    
    if ($TestV3Compatibility) {
        Write-LogMessage "Testing v3 compatibility mode specifically" -Type "Info"
    }
    
    # Initialize results object
    $results = @{
        StructureValid = $false
        ScriptValid = $false
        ModuleImportValid = $false
        TemplateType = "Unknown"
        MissingFiles = @()
        Issues = @()
    }
    
    # Run validation tests
    Write-LogMessage "`n=== STRUCTURE VALIDATION ===" -Type "Info"
    $structureOk = Test-PSADT4Structure -Path $PackagePath -Results ([ref]$results)
    
    Write-LogMessage "`n=== SCRIPT VALIDATION ===" -Type "Info"
    $scriptOk = Test-DeployScript -Path $PackagePath -SkipSyntax $SkipSyntaxCheck -TestV3Mode $TestV3Compatibility -Results ([ref]$results)
    
    Write-LogMessage "`n=== MODULE IMPORT TEST ===" -Type "Info"
    $moduleOk = Test-ModuleImport -Path $PackagePath -Results ([ref]$results)
    
    # Overall assessment
    Write-LogMessage "`n=== OVERALL ASSESSMENT ===" -Type "Info"
    $overallValid = $structureOk -and $scriptOk -and $moduleOk
    
    if ($overallValid) {
        Write-LogMessage "✅ PACKAGE VALIDATION PASSED" -Type "Success"
        Write-LogMessage "Package is ready for deployment" -Type "Success"
    } else {
        Write-LogMessage "❌ PACKAGE VALIDATION FAILED" -Type "Error"
        Write-LogMessage "Package needs attention before deployment" -Type "Error"
    }
    
    Write-LogMessage "`nTemplate Type: $($results.TemplateType)" -Type "Info"
    
    if ($results.Issues.Count -gt 0) {
        Write-LogMessage "`nIssues to address:" -Type "Warning"
        foreach ($issue in $results.Issues) {
            Write-LogMessage "  - $issue" -Type "Warning"
        }
    }
    
    # Generate report if requested
    if ($OutputReport) {
        Write-LogMessage "`n=== GENERATING REPORT ===" -Type "Info"
        $reportFile = New-ValidationReport -PackagePath $PackagePath -Results $results -ReportPath $ReportPath
    }
    
    # Provide recommendations based on template type
    Write-LogMessage "`n=== RECOMMENDATIONS ===" -Type "Info"
    switch ($results.TemplateType) {
        "v4 Native" {
            Write-LogMessage "✅ Using modern v4 ADT-prefixed functions - excellent!" -Type "Success"
            Write-LogMessage "Package follows latest PSADT v4 best practices" -Type "Success"
        }
        "v3 Compatibility" {
            Write-LogMessage "ℹ Using v3 compatibility mode" -Type "Info"
            Write-LogMessage "Consider migrating to v4 native functions for better performance" -Type "Info"
        }
        "Mixed" {
            Write-LogMessage "⚠ Mixed function usage detected" -Type "Warning"
            Write-LogMessage "Standardize on either v3 compatibility or v4 native functions" -Type "Warning"
        }
        "Unknown" {
            Write-LogMessage "⚠ Template type unclear" -Type "Warning"
            Write-LogMessage "Review Deploy-Application.ps1 for proper PSADT function usage" -Type "Warning"
        }
    }
    
    exit $(if ($overallValid) { 0 } else { 1 })
}
catch {
    Write-LogMessage "Validation failed: $($_.Exception.Message)" -Type "Error"
    exit 1
}
#endregion Main Script
