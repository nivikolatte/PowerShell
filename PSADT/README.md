# PSADT 4.0 Automation Suite

A comprehensive automation solution for creating, validating, and managing PowerShell App Deployment Toolkit 4.0 packages using **official v4 methods**. This suite uses the latest PSADT v4 documentation and `New-ADTTemplate` cmdlet for proper compliance.

## 🚀 Features

- **Official v4 Template Support**: Uses `New-ADTTemplate` cmdlet from PSADT v4
- **v4 Native & v3 Compatibility**: Support for both ADT-prefixed functions and legacy compatibility
- **PSADT 4.0 Compliant**: Updated based on official PSADT v4 documentation
- **Automated Package Creation**: Generate complete PSADT packages from minimal input
- **Comprehensive Validation**: Multi-level package validation with template type detection
- **Modern PowerShell**: PowerShell 5.1+ with proper error handling and logging
- **Enterprise Ready**: Detailed logging and reporting

## 📁 Components

### Core Scripts

| Script | Purpose | Description |
|--------|---------|-------------|
| `Initialize-PSADTStructure.ps1` | Setup | Creates development environment |
| `Setup-PSADT4.ps1` | Validation | Validates PSADT 4.0 installation |
| `New-PSADT4Package.ps1` | Creation | Uses official New-ADTTemplate cmdlet |
| `Test-PSADT4Package.ps1` | Validation | Tests official v4 template compliance |

## 🛠️ Quick Start

### 1. Initialize Folder Structure (Recommended)

```powershell
# Create organized folder structure
.\Initialize-PSADTStructure.ps1

# Load the PowerShell profile (from the created structure)
cd C:\PSADT_Automation
. .\PSADT-Profile.ps1
```

### 2. PSADT v4 Installation

- Install PSADT 4.0 from the [official site](https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases)
- Install to the `PSADT4` folder or system-wide location
- Validate with:

```powershell
.\Scripts\Setup-PSADT4.ps1 -InstallPath "C:\PSADT_Automation\PSADT4"
```

### 3. Create Package Using Official v4 Methods (Recommended)

```powershell
# Create v4 native package (uses ADT-prefixed functions)
.\New-PSADT4Package.ps1 -AppName "VLC Media Player" -AppVersion "3.0.20" -AppPublisher "VideoLAN" -SourcePath "C:\Source\VLC" -InstallFile "vlc-3.0.20-win64.exe" -InstallType "EXE"

# Create v3 compatibility package (uses legacy function names)
.\New-PSADT4Package.ps1 -AppName "Legacy App" -AppVersion "1.0" -AppPublisher "OldCorp" -SourcePath "C:\Source\Legacy" -InstallFile "setup.exe" -InstallType "EXE" -UseV3Compatibility
```

### 4. Package Validation with Official v4 Testing

```powershell
# Test v4 native package
.\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Packages\VideoLAN-VLC_Media_Player-3.0.20" -OutputReport

# Test v3 compatibility package
.\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Packages\OldCorp-Legacy_App-1.0" -TestV3Compatibility -OutputReport
```

## 📁 Recommended Folder Structure

Use the `Initialize-PSADTStructure.ps1` script to create this organized structure:

```
C:\PSADT_Automation\
├── Scripts\                    # Automation PowerShell scripts
│   ├── Setup-PSADT4.ps1              # PSADT v4 validation
│   ├── New-PSADT4Package.ps1         # Official v4 template creation
│   ├── Test-PSADT4Package.ps1        # Official v4 template testing
│   └── Initialize-PSADTStructure.ps1 # Environment setup
├── PSADT4\                     # PSADT 4.0 installation
│   ├── PSAppDeployToolkit.psm1  # Main v4 module
│   ├── PSAppDeployToolkit.psd1  # Module manifest
│   └── [other v4 files]
├── Source\                     # Source installer files (organized by vendor)
│   ├── Adobe\                  # Adobe products
│   ├── Microsoft\              # Microsoft products
│   ├── Google\                 # Google products
│   ├── Mozilla\                # Mozilla products
│   └── Other\                  # Other vendors
├── Packages\                   # Generated PSADT packages
├── Logs\                       # Execution logs
├── Reports\                    # Validation reports
├── Documentation\              # Guides and documentation
├── PSADT-Profile.ps1          # PowerShell profile with helper functions
└── README.md                  # Main documentation
```

## 🎯 Template Types

### v4 Native Templates (Recommended)
Uses modern ADT-prefixed functions introduced in PSADT v4:
- `Start-ADTProcess` (instead of `Execute-Process`)
- `Start-ADTMsiProcess` (instead of `Execute-MSI`)
- `Show-ADTInstallationWelcome` (instead of `Show-InstallationWelcome`)
- `Show-ADTInstallationPrompt` (instead of `Show-InstallationPrompt`)

**Benefits:**
- Latest v4 features and improvements
- Better performance and reliability
- Future-proof compatibility

### v3 Compatibility Templates
Uses familiar v3 function names for easier migration:
- `Execute-Process`
- `Execute-MSI`
- `Show-InstallationWelcome`
- `Show-InstallationPrompt`

**Benefits:**
- Easier migration from existing v3 scripts
- Familiar function names
- Gradual transition path to v4

## 📝 Requirements

- **PowerShell 5.1 or later**
- **PSADT 4.0** (downloaded and installed)
- **Administrator privileges** for package testing
- **Sufficient disk space** for package creation and logs

## 🔄 Migration from PSADT 3.x

The automation suite now supports both v4 native and v3 compatibility modes:

### For New Projects (Recommended)
Use v4 native templates with ADT-prefixed functions:
```powershell
.\New-PSADT4Package.ps1 [parameters] # Creates v4 native template
```

### For Migration Projects
Use v3 compatibility templates to ease transition:
```powershell
.\New-PSADT4Package.ps1 [parameters] -UseV3Compatibility
```

### Key v4 Changes
1. **Function Names**: ADT-prefixed functions (e.g., `Start-ADTProcess`)
2. **Session Management**: Uses `Open-ADTSession` for initialization
3. **Module Structure**: PSAppDeployToolkit.psm1/psd1 instead of AppDeployToolkitMain.ps1
4. **Template Creation**: Uses official `New-ADTTemplate` cmdlet
5. **Enhanced Features**: Improved error handling and performance

## 🧪 Testing and Validation

### Official v4 Template Validation
```powershell
# Test v4 native package
.\Test-PSADT4Package.ps1 -PackagePath "C:\Packages\MyApp" -OutputReport

# Test v3 compatibility package
.\Test-PSADT4Package.ps1 -PackagePath "C:\Packages\MyApp" -TestV3Compatibility
```

### Validation Features
- **Template Type Detection**: Automatically detects v4 native vs v3 compatibility
- **Function Usage Analysis**: Validates proper ADT-prefixed or legacy function usage
- **Module Import Testing**: Verifies module can be imported successfully
- **Syntax Validation**: PowerShell syntax checking
- **Structure Compliance**: Official v4 template structure validation

## 🤝 Contributing

To enhance the automation suite:

1. **Fork the repository**
2. **Create feature branches** for enhancements
3. **Test thoroughly** with both v4 native and v3 compatibility modes
4. **Update documentation** for new features
5. **Submit pull requests** with detailed descriptions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

#### New-ADTTemplate Cmdlet Not Found
```powershell
# Solution: Ensure PSADT v4 module is properly imported
Import-Module C:\PSADT4\PSAppDeployToolkit.psm1 -Force
Get-Command New-ADTTemplate  # Should return the cmdlet
```

#### PSADT 4.0 Not Found
```powershell
# Solution: Ensure PSADT 4.0 is properly installed in the specified folder
.\Setup-PSADT4.ps1 -InstallPath "C:\PSADT4"
```

#### Template Creation Fails
```powershell
# Solution: Check PSADT v4 installation and permissions
.\New-PSADT4Package.ps1 [parameters] -Verbose
```

#### Function Not Recognized Errors
- **v4 Native**: Ensure you're using ADT-prefixed functions (`Start-ADTProcess`)
- **v3 Compatibility**: Ensure you're using legacy function names (`Execute-Process`)
- **Mixed Usage**: Don't mix v3 and v4 functions in the same script

#### Package Validation Fails
```powershell
# Solution: Check detailed validation report
.\Test-PSADT4Package.ps1 -PackagePath $path -OutputReport
```

### Template Type Issues

#### Wrong Template Type Created
```powershell
# For v4 native (uses ADT-prefixed functions)
.\New-PSADT4Package.ps1 [parameters]

# For v3 compatibility (uses legacy function names)
.\New-PSADT4Package.ps1 [parameters] -UseV3Compatibility
```

#### Mixed Function Usage Detected
- Review Deploy-Application.ps1 for mixed v3/v4 function usage
- Standardize on one approach (v4 native recommended)
- Use validation tool to identify specific issues

### Getting Help

1. **Check validation reports** for specific issues and recommendations
2. **Review log files** in the specified log directory
3. **Verify source file paths** and permissions
4. **Ensure PSADT 4.0** is properly installed with New-ADTTemplate cmdlet
5. **Test with single packages** first before batch operations
6. **Use -Verbose** flags for detailed output

### Recommended Workflows

#### For New Deployments
1. Use v4 native templates (`New-PSADT4Package.ps1`)
2. Test with official validation (`Test-PSADT4Package.ps1`)
3. Generate validation reports for documentation

#### For Migration Projects
1. Start with v3 compatibility templates (`-UseV3Compatibility`)
2. Test thoroughly in existing environment
3. Gradually migrate to v4 native functions

## 📞 Support

For issues and questions:
- **Internal Support**: Contact IT Department
- **Documentation**: Review PSADT 4.0 official documentation at https://psappdeploytoolkit.com
- **Community**: PowerShell App Deployment Toolkit community forums
- **Official Repository**: https://github.com/PSAppDeployToolkit/PSAppDeployToolkit

---

*Generated on 2025-01-15 | PSADT 4.0 Automation Suite v3.0.0 | Updated with Official v4 Template Support*
