<#
.SYNOPSIS
    Deploys the DevBox customization tasks catalog to a GitHub repository.

.DESCRIPTION
    This script initializes a Git repository, adds the customization tasks, and pushes them to GitHub.
    It can be used to create a tasks catalog for use with Azure DevBox.
    
    The repository URL is hardcoded in the script for easier deployment.

.PARAMETER Branch
    The branch to push the catalog to. Default is 'main'.

.EXAMPLE
    .\Deploy-CustomizationTasksCatalog.ps1
    
    # To specify a different branch:
    .\Deploy-CustomizationTasksCatalog.ps1 -Branch "development"

.NOTES
    Author: GitHub Copilot
    Date: $(Get-Date -Format "yyyy-MM-dd")
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$Branch = "main"
)

# Hardcoded GitHub repository URL - Change this to your organization's repository
$GitHubRepoUrl = "https://github.com/myorg/devbox-customizations.git"

# Check if git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Please install Git and try again." -ForegroundColor Red
    exit 1
}

# Ensure we're in the CustomizationTasks directory
$customizationTasksDir = "C:\DEV\AZ\PowerShell\DevBox\CustomizationTasks"
if (-not (Test-Path -Path $customizationTasksDir)) {
    Write-Host "Customization tasks directory not found at $customizationTasksDir" -ForegroundColor Red
    exit 1
}

Set-Location $customizationTasksDir

# Initialize Git repository if not already initialized
if (-not (Test-Path -Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Green
    git init
}

# Add remote repository if not already added
$remotes = git remote
if ($remotes -notcontains "origin") {
    Write-Host "Adding remote repository..." -ForegroundColor Green
    git remote add origin $GitHubRepoUrl
}

# Add all files to the repository
Write-Host "Adding files to the repository..." -ForegroundColor Green
git add .

# Commit changes
Write-Host "Committing changes..." -ForegroundColor Green
git commit -m "Add DevBox customization tasks"

# Push to GitHub
Write-Host "Pushing to GitHub..." -ForegroundColor Green
git push -u origin $Branch

Write-Host "Customization tasks catalog has been deployed to GitHub." -ForegroundColor Green
Write-Host "Repository URL: $GitHubRepoUrl" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. In the Azure portal, go to your Dev Center" -ForegroundColor Cyan
Write-Host "2. Select 'Tasks catalogs' from the menu" -ForegroundColor Cyan
Write-Host "3. Click 'Add' to add a new catalog" -ForegroundColor Cyan
Write-Host "4. Enter the repository URL: $GitHubRepoUrl" -ForegroundColor Cyan
Write-Host "5. Select the branch: $Branch" -ForegroundColor Cyan
Write-Host "6. Enter the folder path: /" -ForegroundColor Cyan
Write-Host "7. Click 'Create' to add the catalog" -ForegroundColor Cyan
