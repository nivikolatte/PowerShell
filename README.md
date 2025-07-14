<div align="center">

# 🚀 PowerShell Scripts Repository

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://docs.microsoft.com/en-us/powershell/)
[![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/en-us/windows)
[![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

**🎯 A curated collection of powerful PowerShell scripts for automation and streamlined workflows**

*Boost your productivity with battle-tested scripts designed for real-world scenarios*

---

</div>

## ✨ Features

🔧 **Ready-to-Use Scripts** - Each script is self-contained with comprehensive documentation  
📚 **Well-Documented** - Clear usage examples and parameter explanations  
🔄 **Automation-Focused** - Streamline repetitive tasks and complex workflows  
🛡️ **Production-Ready** - Tested scripts with error handling and best practices  
🏢 **Enterprise-Grade** - Suitable for both personal and professional environments  

## 📂 Repository Structure

```
📦 PowerShell Repository
├── 🔐 AzureAutomation/           # Azure automation scripts
├── 🖥️  AzureVirtualDesktop/      # AVD management tools
├── 📦 DevBox/                    # Azure DevBox customizations
├── 🛠️  PSADT/                    # PowerShell App Deployment Toolkit
├── 📱 WinGet-AutoUpdate/         # Windows package management
├── 🔧 Set-BitlockerStartupPIN    # BitLocker configuration
├── 🎨 Set-CustomLockScreen.ps1   # Windows customization
└── 📄 Transform-GPOXML.ps1       # Group Policy utilities
```

## 🚀 Quick Start

### Prerequisites
- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Windows 10/11** or **Windows Server 2019+**
- **Administrator privileges** (for some scripts)

### Installation

```powershell
# Clone the repository
git clone https://github.com/<your-username>/<your-repo>.git

# Navigate to the repository
cd PowerShell

# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 💡 Usage Examples

### Azure DevBox Customization
```powershell
# Automated repository setup for DevBox
.\DevBox\Clone-RepositoriesAfterDeployment.ps1 -UseHardcodedRepos $true
```

### Windows Package Management
```powershell
# Detect and remediate WinGet updates
.\WinGet-AutoUpdate\Detect-WinGetUpdates-SystemCompatible.ps1
```

### Azure Virtual Desktop
```powershell
# Test AVD client connectivity
.\AzureVirtualDesktop\Test-AVDClientConnectivity.ps1
```

## 🛠️ Featured Scripts

| Script | Description | Category |
|--------|-------------|----------|
| 🔐 **Intune-RemoveLastSynced.ps1** | Remove Intune last sync timestamps | Azure Automation |
| 🖥️ **Test-AVDClientConnectivity.ps1** | Validate AVD client connections | Virtual Desktop |
| 📦 **New-PSADT4Package.ps1** | Create PSADT deployment packages | App Deployment |
| 🔄 **Detect-WinGetUpdates.ps1** | Automated Windows package updates | Package Management |
| 🎨 **Set-CustomLockScreen.ps1** | Customize Windows lock screen | System Configuration |

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **🍴 Fork** the repository
2. **🌿 Create** a feature branch (`git checkout -b feature/amazing-script`)
3. **💻 Code** your improvements
4. **✅ Test** thoroughly in your environment
5. **📝 Document** your changes
6. **🚀 Submit** a pull request

### Contribution Guidelines
- Follow PowerShell best practices and style guides
- Include comprehensive help documentation
- Add error handling and parameter validation
- Test scripts in multiple environments when possible

## 🐛 Issues & Support

Found a bug? Have a feature request? We'd love to hear from you!

<!-- GitHub Issues and PR badges removed for privacy -->

- 🐛 **Report Bugs**: [Create an Issue](https://github.com/<your-username>/<your-repo>/issues/new?template=bug_report.md)
- 💡 **Request Features**: [Feature Request](https://github.com/<your-username>/<your-repo>/issues/new?template=feature_request.md)
- 💬 **Ask Questions**: [Discussions](https://github.com/<your-username>/<your-repo>/discussions)

## 📖 Documentation & Resources

### 📝 Blog
Check out my technical blog for in-depth tutorials and insights:
**[🌐 LocalError.com](https://www.localerror.com/)**

### 📚 Additional Resources
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/)
- [PowerShell Gallery](https://www.powershellgallery.com/)

## ⚖️ License

<div align="center">

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

**This project is licensed under the MIT License**

*You are free to use, modify, and distribute these scripts in compliance with the license terms*

</div>

## ⚠️ Disclaimer

> **Important**: These scripts are provided **AS-IS** without any warranty. While every effort is made to ensure accuracy and functionality, please:
> 
> - 🧪 **Test thoroughly** in your environment before production use
> - 📋 **Review scripts** to understand their functionality
> - 🔒 **Follow security best practices** in your organization
> - 📝 **Backup systems** before running automation scripts

## 🙏 Acknowledgments

Special thanks to the PowerShell community and all contributors who help make this repository better!

---

<div align="center">

**⭐ If you find these scripts helpful, please consider giving this repository a star!**


<!-- GitHub stars and forks badges removed for privacy -->

*Happy Scripting! 🚀*

</div>

