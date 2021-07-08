var cloudConfig = '''
#cloud-config
package_update: true
packages:
  - gridsite-clients
  - jq

write_files:
  - content: |
      #!/bin/bash

      echo \"Installing RKE2 server\"
      curl -sfL https://get.rke2.io | sh -

    path: /root/installRKE2server
    owner: root:root

  - content: |
      vm.max_map_count=262144
    
    path: /etc/sysctl.d/10-vm-map-count.conf
    owner: root:root

  - content: |
      audience=$(urlencode '{audience}')
      access_token=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource='$audience -H Metadata:true | jq -r ".access_token")
      token=$(cat /var/lib/rancher/rke2/server/node-token)
      payload=$(cat <<EOF
      { "value": "$token" }
      EOF
      )
      curl -X PUT {vaultBaseUrl}secrets/rke2ServerJoinToken?api-version=7.2 -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" -d "$payload"

    path: /root/storeServerToken
    owner: root:root

  - content: |

      {
        "cloud": "AzurePublicCloud",
        "tenantId": "{tenant_id}",
        "aadClientId": "__CHANGE_ME__",
        "aadClientSecret": "__CHANGE_ME__",
        "subscriptionId": "__CHANGE_ME__",
        "resourceGroup": "{resource_group}",
        "vmType": "standard",
        "location": "{location}",
        "subnetName": "{subnet_name}",
        "securityGroupName": "{nsg_name}",
        "securityGroupResourceGroup": "{resource_group}",
        "vnetName": "{vnet_name}",
        "vnetResourceGroup": "{resource_group}",
        "routeTableName": "{route_table_name}",
        "cloudProviderBackoff": false,
        "useManagedIdentityExtension": false,
        "useInstanceMetadata": true,
        "loadBalancerSku": "standard",
        "excludeMasterFromStandardLB": false
      }

    path: /root/azure.json
    owner: root:root

  - content: |
      cloud-provider-name: azure
      cloud-provider-config: /root/azure.json

    path: /etc/rancher/rke2/config.yaml
    owner: root:root

  - content: |
      chmod 666 /etc/rancher/rke2/rke2.yaml
      echo $(cat <<EOF
      # set PATH so it includes rancher bin if it exists
      if [ -d "/var/lib/rancher/rke2/bin" ] ; then
        PATH="/var/lib/rancher/rke2/bin:$PATH"
      fi
      export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
      ) >> /home/{username}/.profile

    path: /root/configureAdmin
    owner: root:root


runcmd:
  - [ chmod, +x, /root/installRKE2server ]
  - [ chmod, +x, /root/storeServerToken ]
  - [ chmod, +x, /root/configureAdmin ]


  - [ sh, -c, echo \"####################\" ]
  - [ sh, -c, echo \"Installing and starting RKE2 server\" ]
  - [ sh, -c, echo \"####################\" ]
  - [ /root/installRKE2server ]
  - [ systemctl, enable, rke2-server.service ]
  - [ systemctl, start, rke2-server.service ]

  - [ sysctl, -p, /etc/sysctl.d/10-vm-map-count.conf ]

  - [ sh, -c, echo \"####################\" ]
  - [ sh, -c, echo \"Storing join token in kv\" ]
  - [ sh, -c, echo \"####################\" ]
  - [ /root/storeServerToken ]

  - [ sh, -c, echo \"####################\" ]
  - [ sh, -c, echo \"Configuring access to kubectl\" ]
  - [ sh, -c, echo \"####################\" ]
  - [ /root/configureAdmin ]

'''

output customDataString string = cloudConfig
