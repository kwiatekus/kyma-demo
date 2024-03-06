enable_kyma_modules:
	kubectl apply -f k8s-resources/enable-modules.yaml

provision_hana:
	kubectl wait --for condition=established --timeout=60s crd/serviceinstances.services.cloud.sap.com
	kubectl apply -f k8s-resources/hana-instance.yaml
	kubectl wait --for condition=Ready --timeout=15m serviceinstances/hana
	kubectl apply -f k8s-resources/hana-bindings.yaml

deprovision_hana:
	kubectl delete -f k8s-resources/hana-bindings.yaml
	kubectl delete -f k8s-resources/hana-instance.yaml

deploy_app:
	kubectl wait --for condition=established --timeout=60s crd/functions.serverless.kyma-project.io
	(cd src/cache-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-cache.yaml)
	(cd src/hana-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-hana.yaml)
	cat k8s-resources/fn-template.yaml >> k8s-resources/fn-hana.yaml
	kubectl apply -k k8s-resources

undeploy_app:
	kubectl delete -k k8s-resources

deploy_tracing:
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
	kubectl wait --for condition=established crd/issuers.cert-manager.io
	kubectl apply -k k8s-resources/observability
	kubectl wait --for condition=established crd/jaegers.jaegertracing.io
	kubectl apply -f k8s-resources/observability/jaeger.yaml
	kubectl wait --for condition=established crd/telemetries.telemetry.istio.io
	kubectl apply -f k8s-resources/observability/telemetry.yaml
	kubectl wait --for condition=established crd/tracepipelines.telemetry.kyma-project.io
	kubectl apply -f k8s-resources/observability/tracepipeline.yaml