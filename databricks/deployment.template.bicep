param location string
param force_update string = utcNow()
param identity string
param akv_id string
param akv_uri string
param adb_pat_lifetime string = '60'
param adb_workspace_url string
param adb_workspace_id string
param adb_scope_name string
param adb_cluster_name string = 'variantspark-cluster-01'
param adb_spark_version string = '9.1.x-scala2.12'
param adb_node_type string = 'Standard_D3_v2'
param adb_num_worker string = '3'
param hail_docker_image string = 'projectglow/databricks-hail:0.2.74'
param adb_auto_terminate_min string = '30'
// param LogAWkspId string
// param LogAWkspKey string
param LogAnalyticsName string
param StorageAccountName string


param azmanagementURI string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: StorageAccountName
}

var storageKey = listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value

resource LogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: LogAnalyticsName
}

var LogAWkspId = LogAnalyticsWorkspace.id
var LogAWkspKey = listKeys(LogAnalyticsWorkspace.id, LogAnalyticsWorkspace.apiVersion).primarySharedKey


resource createAdbPATToken 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createAdbPATToken'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    timeout: 'PT5M'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'PAT_LIFETIME'
        value: adb_pat_lifetime
      }
      {
        name: 'AZ_MANAGEMENT_URI'
        value: azmanagementURI
      }
    ]
    scriptContent: loadTextContent('deployment/create_pat.sh')
  }
}

resource secretScopeLink 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'secretScopeLink'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    timeout: 'PT1H'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_SECRET_SCOPE_NAME'
        value: adb_scope_name
      }
      {
        name: 'AKV_ID'
        value: akv_id
      }
      {
        name: 'AKV_URI'
        value: akv_uri
      }
      {
        name: 'ADB_LOG_WKSP_ID'
        value: LogAWkspId
      }
      {
        name: 'ADB_LOG_WKSP_KEY'
        value: LogAWkspKey
      }
      {
        name: 'STORAGE_ACCESS_KEY'
        value: storageKey
      }
      {
        name: 'ADB_PAT_TOKEN'
        value: createAdbPATToken.properties.outputs.token_value
      }
      {
        name: 'AZ_MANAGEMENT_URI'
        value: azmanagementURI
      }
    ]
    scriptContent: loadTextContent('deployment/create_secret_scope.sh')
  }
}

resource uploadFilesToAdb 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'uploadFilesToAdb'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    timeout: 'PT5M'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'AZ_MANAGEMENT_URI'
        value: azmanagementURI
      }      
    ]
    scriptContent: loadTextContent('deployment/pre_cluster_create.sh')
  }
}

resource createAdbCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createAdbCluster'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_SECRET_SCOPE_NAME'
        value: adb_scope_name
      }
      {
        name: 'DATABRICKS_CLUSTER_NAME'
        value: adb_cluster_name
      }
      {
        name: 'DATABRICKS_SPARK_VERSION'
        value: adb_spark_version
      }
      {
        name: 'DATABRICKS_NODE_TYPE'
        value: adb_node_type
      }
      {
        name: 'DATABRICKS_NUM_WORKERS'
        value: adb_num_worker
      }
      {
        name: 'DATABRICKS_AUTO_TERMINATE_MINUTES'
        value: adb_auto_terminate_min
      }
      {
        name: 'HAIL_DOCKER_IMAGE'
        value: hail_docker_image
      }
      {
        name: 'AZ_MANAGEMENT_URI'
        value: azmanagementURI
      }
    ]
    scriptContent: loadTextContent('deployment/create_cluster.sh')
  }
  dependsOn: [
    secretScopeLink
    uploadFilesToAdb
  ]
}

resource configAdbCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'configAdbCluster'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_CLUSTER_ID'
        value: createAdbCluster.properties.outputs.cluster_id
      }
      {
        name: 'AZ_MANAGEMENT_URI'
        value: azmanagementURI
      }      
    ]
    scriptContent: loadTextContent('deployment/post_cluster_create.sh')
  }
}

output patToken string = createAdbPATToken.properties.outputs.token_value
//output patOutput object = createAdbPATToken.properties
// output akvLinkOutput object = secretScopeLink.properties
output adbCluster object = createAdbCluster.properties
