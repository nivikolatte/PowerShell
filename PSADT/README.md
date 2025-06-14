# PSADT 4.0 Automation Suite

A comprehensive automation solution for creating, validating, and managing PowerShell App Deployment Toolkit 4.0 packages. This suite eliminates repetitive tasks and ensures consistent, high-quality package creation following PSADT 4.0 best practices.

## 🚀 Features

- **PSADT 4.0 Compliant**: Updated for latest PSADT 4.0 standards and best practices
- **Automated Package Creation**: Generate complete PSADT packages from minimal input
- **Comprehensive Validation**: Multi-level package validation and testing
- **Modern PowerShell**: PowerShell 5.1+ with proper error handling and logging
- **Security Focused**: Built-in security compliance checks
- **Enterprise Ready**: Detailed logging and reporting

## 📁 Components

### Core Scripts

| Script | Purpose | Description |
|--------|---------|-------------|
| `Setup-PSADT4.ps1` | Setup | Validates manual PSADT 4.0 copy |
| `New-PSADT4Package.ps1` | Creation | Creates individual PSADT packages |
| `Test-PSADT4Package.ps1` | Validation | Validates package compliance and quality |

## 🛠️ Quick Start

### 1. Initialize Folder Structure (Recommended)

```powershell
# Create organized folder structure
.\Initialize-PSADTStructure.ps1

# Load the PowerShell profile (from the created structure)
cd C:\PSADT_Automation
. .\PSADT-Profile.ps1
```

### 2. Manual PSADT Setup

- Download PSADT 4.0 from the [official site](https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases)
- Extract to the `PSADT4` folder
- Validate with:

```powershell
.\Scripts\Setup-PSADT4.ps1 -InstallPath "C:\PSADT_Automation\PSADT4"
```

### 3. Create Single Package

```powershell
# Using profile helper function (after copying installer to Source\Adobe\)
New-PSADTPackage -AppName "Adobe Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE" -SourceFolder "Adobe"

# Or run script directly
.\Scripts\New-PSADT4Package.ps1 -AppName "Adobe Reader" -AppVersion "24.002.20933" -AppPublisher "Adobe" -SourcePath "C:\PSADT_Automation\Source\Adobe" -InstallFile "AdobeReader.exe" -InstallType "EXE"
```

### 4. Package Validation

```powershell
# Using profile helper function
Test-PSADTPackage -PackageName "Adobe-AdobeReader-24.002.20933" -ValidationLevel "Comprehensive"

# Or run script directly
.\Scripts\Test-PSADT4Package.ps1 -PackagePath "C:\PSADT_Automation\Packages\Adobe-AdobeReader-24.002.20933" -ValidationLevel Comprehensive -OutputReport
```

## 📁 Recommended Folder Structure

Use the `Initialize-PSADTStructure.ps1` script to create this organized structure:

```
C:\PSADT_Automation\
├── Scripts\                    # Automation PowerShell scripts
│   ├── Setup-PSADT4.ps1
│   ├── New-PSADT4Package.ps1
│   └── Test-PSADT4Package.ps1
├── PSADT4\                     # PSADT 4.0 installation
│   └── Toolkit\
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

## 📝 Requirements

- **PowerShell 5.1 or later**
- **PSADT 4.0** (manually downloaded and copied)
- **Administrator privileges** for package testing
- **Sufficient disk space** for package creation and logs

## 🎯 Migration from PSADT 3.x

The automation suite is designed specifically for PSADT 4.0. Key differences from 3.x:

1. **PowerShell 5.1 Requirement**: Updated minimum version
2. **Modern Parameter Handling**: Improved validation and binding
3. **Enhanced Error Handling**: Better exception management
4. **Security Improvements**: Updated security practices
5. **Function Updates**: Latest PSADT function calls and parameters

## 🤝 Contributing

To enhance the automation suite:

1. **Fork the repository**
2. **Create feature branches** for enhancements
3. **Test thoroughly** with multiple package types
4. **Update documentation** for new features
5. **Submit pull requests** with detailed descriptions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

#### PSADT 4.0 Not Found
```powershell
# Solution: Ensure you have manually copied PSADT 4.0 to the correct folder
.\Setup-PSADT4.ps1
```

#### Package Validation Fails
```powershell
# Solution: Check detailed validation report
.\Test-PSADT4Package.ps1 -PackagePath $path -ValidationLevel Comprehensive -OutputReport
```

### Getting Help

1. **Check validation reports** for specific issues
2. **Review log files** in the specified log directory
3. **Verify source file paths** and permissions
4. **Ensure PSADT 4.0** is properly installed
5. **Test with single packages**

## 📞 Support

For issues and questions:
- **Internal Support**: Contact IT Department
- **Documentation**: Review PSADT 4.0 official documentation
- **Community**: PowerShell App Deployment Toolkit community forums

---

*Generated on 2025-06-14 | PSADT 4.0 Automation Suite v2.0.0*
