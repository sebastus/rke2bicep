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

runcmd:
  - [ chmod, +x, /root/installRKE2server ]
  - [ chmod, +x, /root/storeServerToken ]


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

'''

output customDataString string = cloudConfig
