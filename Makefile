deploy:
	kubectl apply -f k8s-resources/enable-modules.yaml
	@./hack/verify_kyma_status.sh
	(cd src/hana-fn && kyma apply function --dry-run -oyaml > ../../k8s-resources/fn-hana.yaml)
	cat k8s-resources/fn-template.yaml >> k8s-resources/fn-hana.yaml
	kubectl apply -k k8s-resources

