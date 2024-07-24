#!/bin/bash
set -e


if [ -z "$1" ]
  then
    echo "subaccount name not provided"
	exit 1
fi

if [ -z "$2" ]
  then
    echo "username for human access not provided"
	exit 1
fi

#install kyma CLI into /bin folder
curl -L "https://github.com/kyma-project/cli/releases/download/v0.0.0-dev/kyma_$(uname -s)_$(uname -m).tar.gz" | tar -zxvf - -C ../bin kyma

export $(cat ../env/.env | xargs)


btp login --url $BTP_BACKEND_URL --user $BTP_BOT_USER --password $BTP_BOT_PASSWORD --idp $BTP_CUSTOM_IAS_TENANT

btp set config --format json

##### TODO: REFACTOR USING SAP BTP TERRAFORM provider ------------------------------

BTP_SA_NAME=$1 BTP_SA_REGION=$BTP_SA_REGION make create-subaccount

export BTP_SA_GUID=$(jq -r '.guid' ./tmp/subaccount-output.json)

BTP_SA_GUID=$BTP_SA_GUID KYMA_PLAN=$BTP_KYMA_PLAN make create-entitlements

BTP_CUSTOM_IDP_HOST=$BTP_CUSTOM_IAS_TENANT.$BTP_CUSTOM_IAS_DOMAIN BTP_IAS_APP_NAME=$1-$BTP_CUSTOM_IAS_TENANT make create-custom-idp

BTP_BOT_USER=$BTP_BOT_USER BTP_KYMA_NAME=$1-kyma KYMA_PLAN=$BTP_KYMA_PLAN BTP_KYMA_REGION=$BTP_KYMA_REGION HUMAN_USER=$2 make create-kyma-env

##### ---------------------------------------------------------------------------------


### TODO: refactor getting access to the cluster : use btp CLI or kyma CLI ---

#Generate bot user based access
make headless-kubeconfig

#Generate acces based on service account bound to a selected cluster-role (for the automation purpose) using the one-off bot user based access
CLUSTERROLE=cluster-admin make service-account-kubeconfig

### ---------------------------------------------------------------------------


# TODO: add bindings to statefull service instances provisioned in different subaccount (hana db, btp object store)
# TODO: map hana instance to the new kyma runtime


# TODO: change to enable from experimental channel via kyma v3 cli
KUBECONFIG=tmp/sa-kubeconfig.yaml make enable_docker_registry



# TODO: the following is sort of "kyma push app" equivalent for "cf push"
sleep 5
make docker_registry_login
make docker_build
make docker_push
make deploy_bookstore_app
