# DevBox Repository Configuration with Hardcoded URLs

This folder contains scripts and configuration files to automate repository setup after deploying an Azure DevBox, with support for hardcoded repository URLs.

## Components

1. **Clone-RepositoriesAfterDeployment.ps1** - A PowerShell script that handles repository cloning with hardcoded URLs
2. **CustomizationTasks** - A folder containing DevBox customization tasks
   - **git-clone-repositories** - Task for cloning repositories
   - **customization.yaml** - Sample customization file with hardcoded URLs option

## Hardcoded Repository URLs

The scripts and configuration files now support hardcoded repository URLs, which means:

1. You can define the repositories directly in the script, making it easier to manage and deploy
2. You don't need to specify the repositories each time you run the script
3. You can maintain a consistent set of repositories across all DevBoxes

### Where to Configure Hardcoded URLs

The hardcoded repository URLs are defined in:

1. **Clone-RepositoriesAfterDeployment.ps1** - In the `$hardcodedRepositories` variable
2. **Deploy-CustomizationTasksCatalog.ps1** - The GitHub repository URL is hardcoded in the `$GitHubRepoUrl` variable

### How to Use Hardcoded Repositories

#### In the PowerShell Script

```powershell
# Use hardcoded repositories
.\Clone-RepositoriesAfterDeployment.ps1 -UseHardcodedRepos $true

# Deploy the customization tasks catalog
.\Deploy-CustomizationTasksCatalog.ps1
```

#### In the Customization File

```yaml
# Clone repositories (using hardcoded URLs from the script)
- task: git-clone-repositories
  inputs:
    useHardcodedRepos: true
    scriptPath: ./git-clone-repositories/Clone-RepositoriesAfterDeployment.ps1
```

## Using DevBox Customization Tasks

Azure DevBox supports customization tasks that can be run after a DevBox is deployed. These tasks can be used to automate repository setup, install tools, and perform other configuration actions.

### Setup Steps

1. Create a tasks catalog in GitHub or Azure Repos
2. Attach the catalog to your Dev Center
3. Create customization definitions in your Dev Box project
4. Apply customizations to your Dev Box definition

### Creating a Tasks Catalog

1. Create a GitHub or Azure Repos repository
2. Add your tasks to the repository, with each task in a separate folder
3. Each task folder should contain:
   - A task.yaml file defining the task parameters
   - Any scripts or files needed by the task

### Sample Structure

```
repository-root/
  ├── git-clone-repositories/
  │   ├── task.yaml
  │   ├── Clone-RepositoriesAfterDeployment.ps1
  ├── customization.yaml
```

### Attaching a Catalog to Your Dev Center

1. In the Azure portal, go to your Dev Center
2. Select "Tasks catalogs" from the menu
3. Click "Add" to add a new catalog
4. Enter the repository URL and other required information
5. Click "Create" to add the catalog

### Creating a Customization Definition

1. In the Azure portal, go to your Dev Box project
2. Select "Customization definitions" from the menu
3. Click "Create" to create a new definition
4. Select the tasks you want to include in the definition
5. Configure the task parameters
6. Click "Create" to save the definition

### Applying Customizations to Your Dev Box Definition

1. In the Azure portal, go to your Dev Box project
2. Select "Dev Box definitions" from the menu
3. Select the definition you want to modify
4. Click "Edit" to edit the definition
5. In the "Customizations" section, select the customization definition you created
6. Click "Save" to update the definition

## Sample Customization File

The sample customization.yaml file includes:

1. Repository cloning using the git-clone-repositories task
2. Installation of common tools using WinGet
3. Optional PowerShell commands for additional customization

You can modify this file to suit your specific requirements.

## Resources

- [Create tasks for Dev Box team customizations](https://learn.microsoft.com/en-us/azure/dev-box/how-to-create-customization-tasks-catalog)
- [Azure DevBox documentation](https://learn.microsoft.com/en-us/azure/dev-box/)
