#!/bin/bash
set -e

# PREREQUISITES

# shared mailbox (bot user): https://sapit-home-prod-004.launchpad.cfapps.eu10.hana.ondemand.com/site/Home?sap-language=en#rmmt2uiuser-Display?sap-ui-app-id-hint=1dc4d034-7c78-4d79-bc17-39a70945fce6
# BTP GA
# custom SAP IAS tenant (either by subscription or manual self-service ) : https://help.sap.com/docs/cloud-identity-services/cloud-identity-services/get-your-tenant
# trust established between GA and custom IAS tenant
# bot user added as a P-user in the custom IAS tenant
# bot user added to GA admin role collection

if [ -z "$1" ]
  then
    echo "subaccount name not provided"
	exit 1
fi

# make btp-login
export $(cat ../env/.env | xargs)

btp login --url $BTP_BACKEND_URL --user $BTP_BOT_USER --password $BTP_BOT_PASSWORD --idp $BTP_CUSTOM_IAS_TENANT

btp set config --format json

BTP_SA_NAME=$1 BTP_SA_REGION=$BTP_SA_REGION make create-subaccount

export BTP_SA_GUID=$(jq -r '.guid' ./tmp/subaccount-output.json)

BTP_SA_GUID=$BTP_SA_GUID KYMA_PLAN=$BTP_KYMA_PLAN make create-entitlements

BTP_CUSTOM_IDP_HOST=$BTP_CUSTOM_IAS_TENANT.$BTP_CUSTOM_IAS_DOMAIN BTP_IAS_APP_NAME=$1-$BTP_CUSTOM_IAS_TENANT make create-custom-idp

BTP_BOT_USER=$BTP_BOT_USER BTP_KYMA_NAME=$1-kyma KYMA_PLAN=$BTP_KYMA_PLAN BTP_KYMA_REGION=$BTP_KYMA_REGION make create-kyma-env

make headless-kubeconfig
make access-kyma
