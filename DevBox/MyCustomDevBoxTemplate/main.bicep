@description('The name of the Devcenter resource e.g. [devCenterName]-[autoGeneratedUniqueString]-dc. The autoGeneratedUniqueString will be 6 characters long.')
param devCenterName string

@description('The name of the Project resource e.g. [projectName]')
param projectName string

@description('A Microsoft Hosted Network Pool in the region of the resouce group. The name of the Pool resource e.g. [poolName]-[region]-pool')
param poolName string

@description('The compute size for the DevBox. Available options include: general_i_8c32gb256ssd_v2, general_i_16c64gb512ssd_v2, general_i_32c128gb512ssd_v2')
@allowed([
  'general_i_8c32gb256ssd_v2'  // 8 vCPU, 32 GB RAM, 256 GB SSD
  'general_i_16c64gb512ssd_v2' // 16 vCPU, 64 GB RAM, 512 GB SSD
  'general_i_32c128gb512ssd_v2' // 32 vCPU, 128 GB RAM, 512 GB SSD
])
param computeSku string = 'general_i_16c64gb512ssd_v2'

@description('The storage size for the DevBox. Available options include: 256gb, 512gb, 1024gb')
@allowed([
  '256gb'
  '512gb'
  '1024gb'
])
param storageSize string = '512gb'

@description('The base image for the DevBox. Default is Windows 11 Enterprise with Visual Studio 2022.')
@allowed([
  'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2' // Windows 11 + VS 2022
  'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-gen2' // Windows 11 + VS 2022 (without M365)
  'microsoftwindowsdesktop_windows-ent-cpc_win11-22h2-ent-cpc-os' // Windows 11 (clean)
])
param baseImage string = 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'

@description('Whether developers should have local administrator rights on their DevBox')
@allowed([
  'Enabled'
  'Disabled'
])
param localAdministrator string = 'Enabled'

@description('Whether hibernation support is enabled for DevBoxes')
@allowed([
  'Enabled'
  'Disabled'
])
param hibernateSupport string = 'Enabled'

var location = resourceGroup().location
var roleDefinitionId = '45d50f46-0b78-4001-a660-4198cbe8cd05' // DevCenter DevBox User
var principalId = deployer().objectId
var devCenterUniqueName = '${devCenterName}-${substring(uniqueString(resourceGroup().id),0,6)}-dc'
var formattedPoolName = '${poolName}-${location}-pool'
var poolPropertyNetworkType = 'Managed'
var poolPropertyNetworkName = 'mhn-network'
var devBoxDefinitionName = '${devCenterName}-${uniqueString(devCenterName)}-devboxdefinition'

resource devCenterUnique 'Microsoft.DevCenter/devcenters@2024-10-01-preview' = {
  name: devCenterUniqueName
  location: location
  tags: {
    'hidden-created-with': 'custom-devbox-template'
    environment: 'development'
    creator: 'github-copilot'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    projectCatalogSettings: {
      catalogItemSyncEnableStatus: 'Enabled'
    }
    networkSettings: {
      microsoftHostedNetworkEnableStatus: 'Enabled'
    }
    devBoxProvisioningSettings: {
      installAzureMonitorAgentEnableStatus: 'Enabled'
    }
  }
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' = {
  name: projectName
  location: location
  tags: {
    'hidden-created-with': 'custom-devbox-template'
    environment: 'development'
    creator: 'github-copilot'
  }
  properties: {
    devCenterId: devCenterUnique.id
  }
}

resource id_id_principalId_roleDefinitionId 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: project
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    description: 'Allows deployer to create dev boxes in the project resource.'
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

resource devCenterUniqueName_devBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2024-08-01-preview' = {
  parent: devCenterUnique
  name: devBoxDefinitionName
  location: location
  tags: {
    'hidden-created-with': 'custom-devbox-template'
    environment: 'development'
    creator: 'github-copilot'
  }
  properties: {
    imageReference: {
      id: '${devCenterUnique.id}/galleries/default/images/${baseImage}'
    }
    sku: {
      name: computeSku
    }
    osStorageType: 'ssd_${storageSize}'
    hibernateSupport: hibernateSupport
  }
}

resource projectName_formattedPool 'Microsoft.DevCenter/projects/pools@2024-10-01-preview' = {
  parent: project
  name: formattedPoolName
  location: location
  tags: {
    'hidden-created-with': 'custom-devbox-template'
    environment: 'development'
    creator: 'github-copilot'
  }
  properties: {
    devBoxDefinitionName: devBoxDefinitionName
    licenseType: 'Windows_Client'
    localAdministrator: localAdministrator
    managedVirtualNetworkRegions: [
      location
    ]
    virtualNetworkType: poolPropertyNetworkType
    networkConnectionName: '${poolPropertyNetworkName}-${location}'
  }
}

// Outputs to help identify the resources created
output devCenterName string = devCenterUnique.name
output devCenterResourceId string = devCenterUnique.id
output projectName string = project.name
output projectResourceId string = project.id
output devBoxDefinitionName string = devBoxDefinitionName
output devBoxPoolName string = projectName_formattedPool.name
output devPortalUrl string = 'https://devportal.microsoft.com'
