set_envs:
	export $(cat env/.env | xargs)

echo_envs:
	echo ${PLAN}

kyma_provision:
	bin/kyma.sh provision --credentials-path=${CIS_CONFIG_PATH} --region=${REGION}  --plan=${PLAN} --owner=${OWNER} --cluster-name=${CLUSTER_NAME}

hana_map:
	bin/kyma.sh hana map --name=hana

enable_kyma_modules:
	kubectl apply -f k8s-resources/enable-modules.yaml

hana_provision:
	kubectl wait --for condition=established --timeout=60s crd/serviceinstances.services.cloud.sap.com
	kubectl apply -f k8s-resources/hana-instance.yaml
	kubectl wait --for condition=Ready --timeout=15m serviceinstances/hana
	kubectl apply -f k8s-resources/hana-bindings.yaml

hana_deprovision:
	kubectl delete -f k8s-resources/hana-bindings.yaml
	kubectl delete -f k8s-resources/hana-instance.yaml
	kubectl delete -f k8s-resources/hana-hdi-binding.yaml
	kubectl delete -f k8s-resources/hana-hdi-instance.yaml

#doesnt work for now..
hana_init:
	kubectl apply -f k8s-resources/hana-hdi-instance.yaml
	kubectl wait --for condition=Ready --timeout=15m serviceinstances/hana-hdi-books
	kubectl apply -f k8s-resources/hana-hdi-binding.yaml
	kubectl wait --for condition=Ready --timeout=15m servicebindings/hana-hdi-books-binding

	kubectl apply -f k8s-resources/hana-hdi-job-src.yaml
	kubectl apply -f k8s-resources/hana-hdi-job.yaml

deploy_app:
#	kubectl wait --for condition=established --timeout=60s crd/functions.serverless.kyma-project.io
#	(cd src/hana-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-hana.yaml)
#   cat k8s-resources/fn-template.yaml >> k8s-resources/fn-hana.yaml
	kubectl apply -k k8s-resources
	kubectl apply -k k8s-resources/docker-registry-secret

undeploy_app:
	kubectl delete -k k8s-resources

tracing_deploy:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
	kubectl wait --for condition=established crd/issuers.cert-manager.io
	kubectl apply -k k8s-resources/observability
	kubectl wait --for condition=established crd/jaegers.jaegertracing.io
	kubectl apply -f k8s-resources/observability/jaeger.yaml
	kubectl wait --for condition=established crd/telemetries.telemetry.istio.io
	kubectl apply -f k8s-resources/observability/telemetry.yaml
	kubectl wait --for condition=established crd/tracepipelines.telemetry.kyma-project.io
	kubectl apply -f k8s-resources/observability/tracepipeline.yaml

tracing_disable:
	kubectl delete -f k8s-resources/observability/tracepipeline.yaml

tracing_enable:
	kubectl apply -f k8s-resources/observability/tracepipeline.yaml