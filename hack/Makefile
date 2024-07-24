.PHONY: create-subaccount
create-subaccount: 
	@btp create accounts/subaccount \
	--display-name ${BTP_SA_NAME} \
	--region ${BTP_SA_REGION} \
	--used-for-production false \
	--subdomain ${BTP_SA_NAME}  \
	--description ${BTP_SA_NAME} > ./tmp/subaccount-output.json
	@until [ "$$(btp get accounts/subaccount $$(jq -r '.guid' ./tmp/subaccount-output.json) | jq  -r '. | .state' )"  = "OK" ] ; \
	do \
	echo "creating subaccount..."  ;\
	  sleep 10 ; \
	  if [ "$$(btp get accounts/subaccount $$(jq -r '.guid' ./tmp/subaccount-output.json) | jq  -r '. | .state' )"  = "OK" ] ; \
	  then \
	    echo "subaccount created" ; \
	  else \
	    echo "creating subaccount..." ; \
	  fi  ; \
	done 
	@btp target -sa $$(jq -r '.guid' ./tmp/subaccount-output.json)

.PHONY: create-entitlements
create-entitlements:
	@btp assign accounts/entitlement --to-subaccount ${BTP_SA_GUID} --for-service kymaruntime --plan ${KYMA_PLAN} --amount 1
	@btp assign accounts/entitlement --to-subaccount ${BTP_SA_GUID} --for-service identity --plan application --enable

.PHONY: create-custom-idp
create-custom-idp: ## trust custom idp in the subaccount and create OIDC application with kyma specific configuration
	@btp create security/trust --name ${BTP_IAS_APP_NAME}-trust --idp ${BTP_CUSTOM_IDP_HOST}
	@jq '. + { name: "${BTP_IAS_APP_NAME}-oidc-app", "display-name": "${BTP_IAS_APP_NAME}-oidc-app"} ' ias-app-params-template.json > tmp/ias-app-params.json
	@btp create services/instance  --offering-name identity --plan-name application --name ${BTP_IAS_APP_NAME}-oidc-app --parameters tmp/ias-app-params.json > ./tmp/create-idp-app-output.json
	@until [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-app-output.json) | jq -r '. | .ready ' )"  = "true" ] ; \
	do \
	  echo "creating OIDC application ${BTP_IAS_APP_NAME}..."  ;\
	  sleep 2 ; \
	  if [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-app-output.json) | jq -r '. | .ready ' )"  = "false" ] ; \
	  then \
	    echo "creating OIDC application ${BTP_IAS_APP_NAME}..." ; \
	  fi  ; \
	done 
	@btp create services/binding --name ${BTP_IAS_APP_NAME}-oidc-app-binding --instance-name ${BTP_IAS_APP_NAME}-oidc-app  --parameters ias-binding-params-cert.json > ./tmp/create-idp-binding-output.json
	@until [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-binding-output.json) | jq -r '. | .ready ' )"  = "true" ] ; \
	do \
	  echo "creating binding for OIDC application ${BTP_IAS_APP_NAME}..."  ;\
	  sleep 2 ; \
	  if [ "$$(echo | $$(jq  -r '. | .command' ./tmp/create-idp-binding-output.json) | jq -r '. | .ready ' )"  = "false" ] ; \
	  then \
	    echo "creating binding for OIDC application ${BTP_IAS_APP_NAME}..." ; \
	  fi  ; \
	done 
	@btp get services/binding --name ${BTP_IAS_APP_NAME}-oidc-app-binding | jq '.credentials | { clientid,  url }' > ./tmp/idp-output.json

.SILENT:
.PHONY: create-kyma-env
create-kyma-env: 
	jq 'input as $$idp | . + { name: "${BTP_KYMA_NAME}", region:"${BTP_KYMA_REGION}", administrators: ["${BTP_BOT_USER}", "${HUMAN_USER}"]} | .oidc |= . + { clientID: $$idp.clientid , issuerURL: $$idp.url  }' kyma-env-params-template.json tmp/idp-output.json > tmp/kyma-params.json
	btp create accounts/environment-instance --display-name ${BTP_KYMA_NAME} --environment kyma --service kymaruntime --plan ${KYMA_PLAN} --parameters tmp/kyma-params.json > tmp/kyma-output.json
	until [ "$$(btp get accounts/environment-instance $$(jq -r '. | .id' tmp/kyma-output.json) | jq -r '. | .state ')" = "OK" ] ; \
	do \
	  echo "kymaruntime creation in progress......"  ;\
	  sleep 30 ; \
	  if [ "$$(btp get accounts/environment-instance $$(jq -r '. | .id' tmp/kyma-output.json) | jq -r '. | .state ')" = "CREATING" ] ; \
	  then \
	    echo "not ready yet. please continue waiting..." ; \
	  fi  ; \
	  if [ "$$(btp get accounts/environment-instance $$(jq -r '. | .id' tmp/kyma-output.json) | jq -r '. | .state ')" = "CREATION_FAILED" ] ; \
	  then \
	    echo "$$(btp get accounts/environment-instance $$(jq -r '. | .id' tmp/kyma-output.json) | jq -r '. | .stateMessage ')" ; \
	    echo "failed. aborting..." ; \
	    break; \
	  fi  ; \
	done

.PHONY: headless-kubeconfig
headless-kubeconfig:
	curl -o tmp/kubeconfig.yaml $$(btp list accounts/environment-instance | jq -r '.environmentInstances[] | select(.serviceName == "kymaruntime") | .labels | fromjson | .KubeconfigURL '  )
	kubectl config view --minify --raw -ojson --kubeconfig tmp/kubeconfig.yaml > tmp/kubeconfig.json 
	jq 'input as  $$exec | .users[0].user.exec=$$exec' tmp/kubeconfig.json kubeconfig-user-exec-template.json > tmp/headless-kubeconfig.json

.PHONY: service-account-kubeconfig
service-account-kubeconfig:
	@echo "Generating expiring service-account based kubeconfig..."
	../bin/kyma alpha access --clusterrole ${CLUSTERROLE} --kubeconfig tmp/headless-kubeconfig.json --name ci-workflow-sa --time 1h --output tmp/sa-kubeconfig.yaml
	@echo "Service-account based kubeconfig generated"

.PHONY: access-kyma
access-kyma:
	kubectl get nodes --kubeconfig tmp/headless-kubeconfig.json

.PHONY: docker_build
docker_build:
	docker buildx build -t bookstore:0.0.1 ..  

.PHONY: docker_push
docker_push:
	docker tag bookstore:0.0.1 $$(kubectl get dockerregistries.operator.kyma-project.io -n kyma-system default -ojsonpath={.status.externalAccess.pushAddress})/bookstore:0.0.1
	docker push $$(kubectl get dockerregistries.operator.kyma-project.io -n kyma-system default -ojsonpath={.status.externalAccess.pushAddress})/bookstore:0.0.1

.PHONY: enable_docker_registry
enable_docker_registry:
	@echo "Enabling docker registry"
	@kubectl apply -f https://github.com/kyma-project/docker-registry/releases/latest/download/dockerregistry-operator.yaml --kubeconfig ${KUBECONFIG}
	@kubectl set image deployment dockerregistry-operator -n kyma-system manager=europe-docker.pkg.dev/kyma-project/prod/dockerregistry-operator:6c4cb8cc3bb0a67e8c91787f251361d732555ec5 --kubeconfig ${KUBECONFIG}
	@kubectl apply -f https://raw.githubusercontent.com/kyma-project/docker-registry/main/config/samples/exposed-dockerregistry-cr.yaml -n kyma-system --kubeconfig ${KUBECONFIG}
	@echo "..waiting for docker registry"
	@kubectl wait --for condition=Installed dockerregistries.operator.kyma-project.io/default -n kyma-system --timeout=60s
	@echo "Docker registry installed"

.PHONY: docker_registry_login
docker_registry_login:
	@echo "Loging Docker CLI into kyma internal docker registry..."
	@docker login -u $$(kubectl get secrets -n kyma-system dockerregistry-config-external -o jsonpath={.data.username} | base64 -d) -p $$(kubectl get secrets -n kyma-system dockerregistry-config-external -o jsonpath={.data.password} | base64 -d) $$(kubectl get dockerregistries.operator.kyma-project.io -n kyma-system default -ojsonpath={.status.externalAccess.pushAddress})

.PHONY: deploy_bookstore_app
deploy_bookstore_app:
	@echo "Deploying bookstore service..."
	@kubectl apply -k ../k8s-resources/bookstore
	@kubectl set image deployment bookstore-service bookstore-service=$$(kubectl get dockerregistries.operator.kyma-project.io -n kyma-system default -ojsonpath={.status.internalAccess.pullAddress})/bookstore:0.0.1
	@echo "Waiting for bookstore service..."
	@kubectl wait --for condition=Available deployment/bookstore-service
	@echo "Bookstore service available." 

