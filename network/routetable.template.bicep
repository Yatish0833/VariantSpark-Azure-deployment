@description('Azure datacentre Location to deploy the Firewall and IP Address')
param routeTableLocation string
@description('Name of the Routing Table')
param routeTableName string

resource routeTableName_resource 'Microsoft.Network/routeTables@2022-05-01' = {
  name: routeTableName
  location: routeTableLocation
  properties: {
    disableBgpRoutePropagation: false
  }
}

output routeTblName string = routeTableName_resource.name
