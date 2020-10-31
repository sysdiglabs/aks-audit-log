
INSTALLER_IMAGE=sysdiglabs/aks-audit-log-installer
INSTALLER_MAYOR=1
INSTALLER_MINOR=1.1

FORWARDER_IMAGE=sysdiglabs/aks-audit-log-installer
FORWARDER_IMAGE=1
FORWARDER_IMAGE=1.0.0
FORWARDER_DIR=./AKSKubeAuditReceiverSolution/
FORWARDER_DOCKERFILE=${FORWARDER_DIR}/AKSKubeAuditReceiver/Dockerfile

RESOURCE_GROUP="aks-test-group"
CLUSTER_NAME="aks-test-cluster"
SYSDIG_SECURE_API_TOKEN=$(shell cat ${KEYS}/SYSDIG_SECURE_API_TOKEN)
DOCKERHUB_USERNAME=$(shell cat ${KEYS}/DOCKER_USER)
DOCKERHUB_PASSWORD=$(shell cat ${KEYS}/DOCKER_PASS)
DOCKERHUB_ORG=sysdiglabs

installer-build-dev:
	docker build . -f build/Dockerfile -t ${INSTALLER_IMAGE}:dev

installer-push-dev:
	docker push ${INSTALLER_IMAGE}:dev

installer-build:
	docker build . -f build/Dockerfile -t ${INSTALLER_IMAGE}:latest \
		-t ${INSTALLER_IMAGE}:${INSTALLER_MAYOR} -t ${INSTALLER_IMAGE}:${INSTALLER_MINOR}

installer-push: check-shell installer-build inline-scan
	docker push ${INSTALLER_IMAGE}:latest
	docker push ${INSTALLER_IMAGE}:${INSTALLER_MAYOR}
	docker push ${INSTALLER_IMAGE}:${INSTALLER_MINOR}

installer-dockerhub-readme:
	echo 'Updating Dockerhub description' ; \
	echo 'Readme: ${PWD}/build/README.md' ; \
	echo 'Repository: ${INSTALLER_IMAGE}' ; \
	docker run -v ${PWD}/build:/workspace \
		-e DOCKERHUB_USERNAME='${DOCKERHUB_USERNAME}' \
		-e DOCKERHUB_PASSWORD='${DOCKERHUB_PASSWORD}' \
		-e DOCKERHUB_REPOSITORY='${INSTALLER_IMAGE}' \
		-e README_FILEPATH='/workspace/README.md' \
		peterevans/dockerhub-description:2

forwarder-build-dev:
	docker build ${FORWARDER_DIR} -f ${FORWARDER_DIR}/Dockerfile -t ${FORWARDER_IMAGE}:dev

forwarder-push-dev:
	docker push ${FORWARDER_IMAGE}:dev

forwarder-build:
	docker build ${FORWARDER_DIR} -f ${FORWARDER_DOCKERFILE} \
		-t ${FORWARDER_IMAGE}:latest -t ${FORWARDER_IMAGE}:${FORWARDER_MAYOR} -t ${FORWARDER_IMAGE}:${FORWARDER_MINOR}

forwarder-push: check installer-build inline-scan
	docker push ${FORWARDER_IMAGE}:latest
	docker push ${FORWARDER_IMAGE}:${FORWARDER_IMAGE}
	docker push ${FORWARDER_IMAGE}:${FORWARDER_IMAGE}


install:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		sysdiglabs/aks-audit-log-installer:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}

uninstall:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		--entrypoint /app/uninstall-aks-audit-log.sh \
		sysdiglabs/aks-audit-log-installer:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}

check: check-shell check-yaml check-dotnet

check-shell:
	docker run --rm --mount type=bind,source=$(PWD)/,target=/data koalaman/shellcheck shellcheck /data/*.sh

check-yaml:
	yamllint ./*.yaml*

check-dotnet:
	# Dotnet lint install dotnet-format for linting
	dotnet tool install -g dotnet-format --version 3.3.111304 ||:
    # Dotnet lint check with dotnet-format
	dotnet format --folder AKSKubeAuditReceiverSolution/ --check --dry-run || true
    # Dotnet build solution
	dotnet build AKSKubeAuditReceiverSolution/AKSKubeAuditReceiver.sln
    # Dotnet test solution
	dotnet test AKSKubeAuditReceiverSolution/AKSKubeAuditReceiver.sln

inline-scan:
	@curl -s https://download.sysdig.com/stable/inline_scan.sh | \
		bash -s -- \
		analyze -s https://secure.sysdig.com -o -k ${SYSDIG_SECURE_API_TOKEN} ${INSTALLER_IMAGE} ; \
	RESULT=$$? ; \
	echo ; echo "******************************" ; \
	[ "$$RESULT" -eq 0 ] && echo "** Scan result  > PASS <    **" ; \
	[ "$$RESULT" -eq 1 ] && echo "** Scan result  > FAIL <    **" ; \
	[ "$$RESULT" -eq 2 ] && echo "** Wrong script invokation  **" ; \
	[ "$$RESULT" -eq 3 ] && echo "** Runtime error            **" ; \
	echo "******************************" ; echo ; exit $$RESULT
