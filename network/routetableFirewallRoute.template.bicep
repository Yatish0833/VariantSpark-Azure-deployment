
param routeTableName string
param firewallPrivateIp string

resource routeTableName_Firewall_Route 'Microsoft.Network/routeTables/routes@2022-05-01' = {
  name: '${routeTableName}/Firewall-Route'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
    hasBgpOverride: false
  }
}

