<#
.SYNOPSIS
    Script to clone repositories after DevBox deployment.

.DESCRIPTION
    This script is designed to be used as part of DevBox customization tasks.
    It clones specified repositories to the DevBox after deployment.
    
    The script can use either hardcoded repositories or repositories passed as parameters.

.PARAMETER Repositories
    Array of repository objects containing URL, TargetPath, and Branch information.
    If not provided, the script will use hardcoded repositories.

.PARAMETER UseHardcodedRepos
    If set to $true, the script will use hardcoded repositories defined in the script.
    Default is $false.

.EXAMPLE
    # Using hardcoded repositories
    .\Clone-RepositoriesAfterDeployment.ps1 -UseHardcodedRepos $true
    
    # Using custom repositories
    $repos = @(
        @{
            URL = "https://github.com/myorg/repo1.git"
            TargetPath = "C:\Projects\repo1"
            Branch = "main"
        },
        @{
            URL = "https://github.com/myorg/repo2.git"
            TargetPath = "C:\Projects\repo2"
            Branch = "develop"
        }
    )

    .\Clone-RepositoriesAfterDeployment.ps1 -Repositories $repos

.NOTES
    Author: GitHub Copilot
    Date: $(Get-Date -Format "yyyy-MM-dd")
#>

param (
    [Parameter(Mandatory = $false)]
    [array]$Repositories,
    
    [Parameter(Mandatory = $false)]
    [bool]$UseHardcodedRepos = $false
)

# Define hardcoded repositories
# These will be used if -UseHardcodedRepos is $true or if no Repositories are provided
$hardcodedRepositories = @(
    @{
        URL = "https://github.com/youractualorg/actual-repo1.git"
        TargetPath = "C:\Projects\actual-repo1"
        Branch = "main"
    },
    @{
        URL = "https://github.com/youractualorg/actual-repo2.git"
        TargetPath = "C:\Projects\actual-repo2"
        Branch = "develop"
    },
    @{
        URL = "https://dev.azure.com/yourorg/yourproject/_git/your-azure-repo"
        TargetPath = "C:\Projects\azure-repo"
        Branch = "main"
    }
)

# Use hardcoded repositories if specified or if no repositories are provided
if ($UseHardcodedRepos -or $null -eq $Repositories -or $Repositories.Count -eq 0) {
    Write-Host "Using hardcoded repositories..." -ForegroundColor Yellow
    $Repositories = $hardcodedRepositories
}

# Ensure git is installed
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Installing git..." -ForegroundColor Green
    winget install --id Git.Git -e --source winget
    
    # Add Git to the current path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}

# Function to clone a repository
function Invoke-GitClone {
    param (
        [string]$Url,
        [string]$TargetPath,
        [string]$Branch = "main"
    )

    # Create target directory if it doesn't exist
    if (-not (Test-Path -Path $TargetPath)) {
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
    }

    # Check if the repository already exists
    if (Test-Path -Path "$TargetPath\.git") {
        Write-Host "Repository already exists at $TargetPath. Pulling latest changes..."
        Push-Location $TargetPath
        git fetch --all
        git checkout $Branch
        git pull
        Pop-Location
    }
    else {
        # Clone the repository
        Write-Host "Cloning repository $Url to $TargetPath..."
        git clone --branch $Branch $Url $TargetPath
    }
}

# Create Projects directory if it doesn't exist
$projectsDir = "C:\Projects"
if (-not (Test-Path -Path $projectsDir)) {
    New-Item -Path $projectsDir -ItemType Directory -Force | Out-Null
}

# Clone each repository
foreach ($repo in $Repositories) {
    $url = $repo.URL
    $targetPath = $repo.TargetPath
    $branch = if ($repo.Branch) { $repo.Branch } else { "main" }

    Invoke-GitClone -Url $url -TargetPath $targetPath -Branch $branch
}

Write-Host "All repositories have been cloned successfully!"
