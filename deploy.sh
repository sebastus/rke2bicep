scriptPath=$(dirname "$0")

test -f secrets.sh        || { echo -e "💥 Error! secrets.sh not found, please create"; exit 1; }
test -f deploy-vars.sh    || { echo -e "💥 Error! deploy-vars.sh not found, please create"; exit 1; }

source $scriptPath/secrets.sh
source $scriptPath/deploy-vars.sh

az group create \
    --location $AZURE_REGION \
    --resource-group $AZURE_RESGRP

az deployment group create \
    -g $AZURE_RESGRP \
    -f ${scriptPath}/infra/main.bicep \
    -n $AZURE_DEPLOY_NAME \
    --parameters \
        resGroupName=$AZURE_RESGRP \
        location=$AZURE_REGION \
        tenantId=$TENANT_ID \
        userObjectId=$USER_OBJECT_ID \
        userIPAddress=$USER_IP_ADDRESS \
        userName=$USER_NAME \
    --mode Complete
