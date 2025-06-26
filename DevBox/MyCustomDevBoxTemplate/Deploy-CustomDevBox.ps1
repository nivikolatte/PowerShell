# Custom DevBox Template Deployment Script
# This script deploys the custom DevBox template to your Azure subscription
# Located in: C:\DEV\AZ\PowerShell\DevBox\MyCustomDevBoxTemplate

# Configuration
$resourceGroupName = "DevBoxResourceGroup"
$location = "eastus"  # Change to your preferred region

# Create a resource group if it doesn't exist
Write-Host "Checking for resource group $resourceGroupName..."
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    Write-Host "Creating resource group $resourceGroupName in $location..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location
} else {
    Write-Host "Resource group $resourceGroupName already exists."
}

# Deploy the template
Write-Host "Deploying custom DevBox template..."
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile ".\main.bicep" `
  -TemplateParameterFile ".\azuredeploy.parameters.json" `
  -Verbose

# Display next steps
Write-Host "======================================================"
Write-Host "Deployment completed! Next steps:"
Write-Host "1. Visit https://devportal.microsoft.com to create your DevBox"
Write-Host "2. Sign in with your Azure account"
Write-Host "3. Select the project you just created"
Write-Host "4. Click 'Create a Dev Box' to create your first DevBox"
Write-Host "======================================================"
