---
description: A customized template for deploying DevBox with configurable options for compute, storage, and base image.
page_type: sample
products:
- azure
- azure-resource-manager
urlFragment: custom-devbox-template
languages:
- bicep
- json
---
# Custom DevBox Deployment Template

## Overview

This template provides a customizable way to set up the resources needed to deploy DevBoxes in your Azure subscription. It's based on the official Azure QuickStart templates but with additional customization options.

The resources created include:

- **Dev Center**: The central management resource for your DevBoxes
- **Dev Box Project**: To organize your DevBoxes
- **Dev Box Definition**: The VM configuration with customizable options
- **Dev Box Pool**: With a Microsoft Hosted Network for simplified connectivity

## Customization Options

This template provides the following customization options:

- **Compute SKU**: Choose between different VM sizes (8 vCPU/32GB RAM, 16 vCPU/64GB RAM, or 32 vCPU/128GB RAM)
- **Storage Size**: Select from 256GB, 512GB, or 1024GB
- **Base Image**: Choose from different Windows 11 images with or without Visual Studio and M365
- **Local Administrator Rights**: Enable or disable local admin rights for users
- **Hibernation Support**: Enable or disable VM hibernation

## Deployment Instructions

### Prerequisites

- An Azure subscription
- Contributor role (or higher) on the subscription
- PowerShell or Azure CLI installed

### Deployment Steps

1. **Create a resource group**:
   ```powershell
   New-AzResourceGroup -Name "MyDevBoxResourceGroup" -Location "eastus"
   ```

2. **Deploy the template**:
   ```powershell
   New-AzResourceGroupDeployment `
     -ResourceGroupName "MyDevBoxResourceGroup" `
     -TemplateFile ".\main.bicep" `
     -TemplateParameterFile ".\azuredeploy.parameters.json" `
     -Verbose
   ```

3. **Access your DevBox**:
   After deployment, go to the [Microsoft Dev Portal](https://devportal.microsoft.com) to create and access your DevBoxes.

## Parameter Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| devCenterName | Name of the Dev Center resource | my-custom-devcenter |
| projectName | Name of the Dev Box project | my-custom-project |
| poolName | Name of the Dev Box pool | my-custom-devboxpool |
| computeSku | VM size for the DevBox | general_i_16c64gb512ssd_v2 |
| storageSize | Storage size for the DevBox | 512gb |
| baseImage | Base image for the DevBox | Win11 + VS2022 + M365 |
| localAdministrator | Enable local admin rights | Enabled |
| hibernateSupport | Enable VM hibernation | Enabled |

## Additional Resources

- [Microsoft Dev Box Documentation](https://learn.microsoft.com/en-us/azure/dev-box/overview-what-is-microsoft-dev-box)
- [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)

`Tags: DevCenter, Dev Box, ARM Template, Microsoft.DevCenter/devcenters, Custom Template`
