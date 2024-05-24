#!/bin/bash
set -e

export $(cat env/.env | xargs)

bin/kyma.sh provision --credentials-path=${CIS_CONFIG_PATH} --region=${REGION}  --plan=${PLAN} --owner=${OWNER} --cluster-name=${CLUSTER_NAME}

# wait via kyma cli

make enable_kyma_modules

make hana_provision

bin/kyma.sh hana map --name=hana

make hana_init