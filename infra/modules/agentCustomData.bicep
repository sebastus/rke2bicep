var cloudConfig = '''
#cloud-config
package_update: true
packages:
  - gridsite-clients
  - jq

write_files:
  - content: |
      #!/bin/bash

      echo \"Installing RKE2 agent\"
      curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

    path: /root/installRKE2agent
    owner: root:root

  - content: |
      vm.max_map_count=262144
    
    path: /etc/sysctl.d/10-vm-map-count.conf
    owner: root:root

  - content: |
      server: https://<rke2server>:9345

    path: /etc/rancher/rke2/config.yaml
    owner: root:root

  - content: |
      audience=$(urlencode '{audience}')
      access_token=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource='$audience -H Metadata:true | jq -r ".access_token")
      token=$(curl '{vaultBaseUrl}secrets/rke2ServerJoinToken?api-version=2016-10-01' -H "Authorization: Bearer ${access_token}" | jq -r ".value")
      echo "token: ${token}" >> "/etc/rancher/rke2/config.yaml"

    path: /root/fetchServerToken
    owner: root:root

runcmd:
  - [ chmod, +x, /root/installRKE2agent ]
  - [ chmod, +x, /root/fetchServerToken ]


  - [ sh, -c, echo \"####################\" ]
  - [ sh, -c, echo \"Installing and enabling RKE2 agent\" ]
  - [ sh, -c, echo \"####################\" ]
  - [ /root/installRKE2agent ]
  - [ systemctl, enable, rke2-agent.service ]

  - [ sysctl, -p, /etc/sysctl.d/10-vm-map-count.conf ]

  - [ sh, -c, echo \"####################\" ]
  - [ sh, -c, echo \"Fetching server join token from kv\" ]
  - [ sh, -c, echo \"####################\" ]
  - [ /root/fetchServerToken ]

  - [ sh, -c, echo \"####################\" ]
  - [ sh, -c, echo \"Starting RKE2 agent\" ]
  - [ sh, -c, echo \"####################\" ]
  - [ systemctl, start, rke2-agent.service ]

'''

output customDataString string = cloudConfig


