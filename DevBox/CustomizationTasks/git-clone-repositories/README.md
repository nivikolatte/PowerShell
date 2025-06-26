# Git Clone Repositories Task

This task clones hardcoded repositories after DevBox deployment.

## Usage

This task is designed to be used in DevBox customization files. The repositories to clone are hardcoded in the `Clone-RepositoriesAfterDeployment.ps1` script.

## Files

- `Clone-RepositoriesAfterDeployment.ps1` - The main PowerShell script that handles repository cloning
- `README.md` - This documentation file

## Configuration

To use this task, reference it in your customization YAML file:

```yaml
tasks:
  - name: powershell
    parameters:
      command: |
        Set-Location "C:\DevBoxCustomizations\git-clone-repositories"
        .\Clone-RepositoriesAfterDeployment.ps1 -UseHardcodedRepos $true
```

## Hardcoded Repositories

The repositories to clone are defined in the `$hardcodedRepositories` array within the PowerShell script. Update this array with your actual repository URLs.

## Dependencies

- Git (automatically installed by the script if not present)
- PowerShell 5.1 or later
