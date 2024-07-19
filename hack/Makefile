.PHONY: create-subaccount
create-subaccount: 
	btp create accounts/subaccount \
	--display-name ${BTP_SA_NAME} \
	--region ${BTP_SA_REGION} \
	--used-for-production false \
	--subdomain ${BTP_SA_NAME}  \
	--description ${BTP_SA_NAME} > ./tmp/subaccount-output.json
	until [ "$$(btp get accounts/subaccount $$(jq -r '.guid' ./tmp/subaccount-output.json) | jq  -r '. | .state' )"  = "OK" ] ; \
	do \
	echo "bootstrap-k8s is running......"  ;\
	  sleep 10 ; \
	  if [ "$$(btp get accounts/subaccount $$(jq -r '.guid' ./tmp/subaccount-output.json) | jq  -r '. | .state' )"  = "OK" ] ; \
	  then \
	    echo "subaccount created..." ; \
	  else \
	    echo "not ready yet. please continue waiting..." ; \
	  fi  ; \
	done 
	btp target -sa $$(jq -r '.guid' ./tmp/subaccount-output.json)

.PHONY: create-entitlements
create-entitlements:
	btp assign accounts/entitlement --to-subaccount ${BTP_SA_GUID} --for-service kymaruntime --plan ${KYMA_PLAN} --amount 1
	btp assign accounts/entitlement --to-subaccount ${BTP_SA_GUID} --for-service identity --plan application --enable

.PHONY: create-custom-idp
create-custom-idp: ## trust custom idp in the subaccount and create OIDC application with kyma specific configuration
	btp create security/trust --name ${BTP_IAS_APP_NAME}-trust --idp ${BTP_CUSTOM_IDP_HOST}
	jq '. + { name: "${BTP_IAS_APP_NAME}-oidc-app", "display-name": "${BTP_IAS_APP_NAME}-oidc-app"} ' ias-app-params-template.json > tmp/ias-app-params.json
	btp create services/instance  --offering-name identity --plan-name application --name ${BTP_IAS_APP_NAME}-oidc-app --parameters tmp/ias-app-params.json > ./tmp/create-idp-app-output.json
	echo | $$(jq  -r '. | .command' ./tmp/create-idp-app-output.json) | jq -r '. '
	until [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-app-output.json) | jq -r '. | .ready ' )"  = "true" ] ; \
	do \
	  echo "bootstrap-custom-idp service creation in progress......"  ;\
	  sleep 2 ; \
	  if [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-app-output.json) | jq -r '. | .ready ' )"  = "false" ] ; \
	  then \
	    echo "not ready yet. please continue waiting..." ; \
	  fi  ; \
	done 
	btp create services/binding --name ${BTP_IAS_APP_NAME}-oidc-app-binding --instance-name ${BTP_IAS_APP_NAME}-oidc-app  --parameters ias-binding-params.json > ./tmp/create-idp-binding-output.json
	echo | $$(jq  -r '. | .command' ./tmp/create-idp-binding-output.json) | jq -r '. '
	until [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-binding-output.json) | jq -r '. | .ready ' )"  = "true" ] ; \
	do \
	  echo "bootstrap-custom-idp service binding creation in progress......"  ;\
	  sleep 2 ; \
	  if [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-binding-output.json) | jq -r '. | .ready ' )"  = "false" ] ; \
	  then \
	    echo "not ready yet. please continue waiting..." ; \
	  fi  ; \
	done 
	btp get services/binding --name ${BTP_IAS_APP_NAME}-oidc-app-binding | jq '.credentials | { clientid,  url }' > ./tmp/idp-output.json

.PHONY:
create-kyma-env: 
	jq 'input as  $$idp | . + { name: "${BTP_KYMA_NAME}", region:"${BTP_KYMA_REGION}", administrators: ["${BTP_BOT_USER}", "krzysztof.kwiatosz@sap.com"]} | .oidc |= . + { clientID: $$idp.clientid , issuerURL: $$idp.url  }' kyma-env-params-template.json tmp/idp-output.json > tmp/kyma-params.json
	btp create accounts/environment-instance --display-name ${BTP_KYMA_NAME} --environment kyma --service kymaruntime --plan ${KYMA_PLAN} --parameters tmp/kyma-params.json > tmp/kyma-output.json