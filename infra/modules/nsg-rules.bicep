var Port9345_Rule = {
  name: 'K8SApi-9345'
  properties: {
    priority: 1010
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '9345'
  }
}
var Port10250_Rule = {
  name: 'MetricsServer'
  properties: {
    priority: 1020
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '10250'
  }
}
var Port2379_Rule = { 
  name: 'etcdClient'
  properties: {
    priority: 1030
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '2379'
  }
}
var Port2380_Rule = {
  name: 'etcdPeer'
  properties: {
    priority: 1040
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '2380'
  }
}
var Port6443_Rule = { 
  name: 'K8SApi-6443'
  properties: {
    priority: 1050
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '6443'
  }
}
var NodePort_Rule = {
  name: 'NodePort'
  properties: {
    priority: 1060
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: '30000-32767'
  }
}


output port9345 object = Port9345_Rule
output port10250 object = Port10250_Rule
output port2379 object = Port2379_Rule
output port2380 object = Port2380_Rule
output port6443 object = Port6443_Rule
output nodePort object = NodePort_Rule
