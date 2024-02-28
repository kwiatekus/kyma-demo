deploy:
	(cd src/hana-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-hana.yaml)
	cat k8s-resources/fn-template.yaml >> k8s-resources/fn-hana.yaml
	kubectl apply -k k8s-resources
	kubectl wait --for condition=Running  functions/hana-fn