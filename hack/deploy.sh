#!/bin/bash
set -e

export $(cat env/.env | xargs)

bin/kyma provision --credentials-path=${CIS_CONFIG_PATH}  --plan=${PLAN} --owner=${OWNER} --parameters=${KYMA_PARAMS}

# wait via kyma cli

# make hana_provision

# bin/kyma.sh hana map --name=hana

# make hana_init