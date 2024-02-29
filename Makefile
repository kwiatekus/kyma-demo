deploy:
	kubectl apply -f k8s-resources/enable-modules.yaml
	kubectl wait --for condition=established --timeout=60s crd/serviceinstances.services.cloud.sap.com
	kubectl apply -f k8s-resources/hana-instance.yaml
	kubectl wait --for condition=established --timeout=60s crd/functions.serverless.kyma-project.io
	(cd src/cache-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-cache.yaml)
	(cd src/hana-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-hana.yaml)
	cat k8s-resources/fn-template.yaml >> k8s-resources/fn-hana.yaml
	kubectl wait --for condition=Ready --timeout=5m serviceinstances/hana
	kubectl apply -k k8s-resources
	kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
	kubectl wait --for condition=established crd/issuers.cert-manager.io
	kubectl apply -k k8s-resources/observability
	kubectl wait --for condition=established crd/jaegers.jaegertracing.io
	kubectl apply -f k8s-resources/observability/jaeger.yaml

	kubectl wait --for condition=established crd/telemetries.telemetry.istio.io
	kubectl apply -f k8s-resources/observability/telemetry.yaml

	kubectl wait --for condition=established crd/tracepipelines.telemetry.kyma-project.io
	kubectl apply -f k8s-resources/observability/tracepipeline.yaml
	


