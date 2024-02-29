deploy:
	kubectl apply -f k8s-resources/enable-modules.yaml
	kubectl wait --for condition=established --timeout=60s crd/serviceinstances.services.cloud.sap.com
	kubectl apply -f k8s-resources/hana-instance.yaml
	kubectl wait --for condition=established --timeout=60s crd/functions.serverless.kyma-project.io
	(cd src/cache-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-cache.yaml)
	(cd src/hana-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-hana.yaml)
	cat k8s-resources/fn-template.yaml >> k8s-resources/fn-hana.yaml
	kubectl wait --for condition=Ready --timeout=60s serviceinstances/hana
	kubectl apply -k k8s-resources

