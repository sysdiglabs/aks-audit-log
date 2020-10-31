
VERSION_FULL=1.0.0
VERSION_MAJOR=$(shell echo "${VERSION_FULL}" | sed 's/[^0-9]*\([0-9]\+\).*/\1/' )

INSTALLER_IMAGE=sysdiglabs/aks-audit-log-installer

FORWARDER_IMAGE=sysdiglabs/aks-audit-log-installer
FORWARDER_DIR=./AKSKubeAuditReceiverSolution
FORWARDER_DOCKERFILE=${FORWARDER_DIR}/AKSKubeAuditReceiver/Dockerfile

RESOURCE_GROUP="aks-test-group"
CLUSTER_NAME="aks-test-cluster"

SYSDIG_SECURE_API_TOKEN=$(shell cat ${KEYS}/SYSDIG_SECURE_API_TOKEN)
DOCKERHUB_USERNAME=$(shell cat ${KEYS}/DOCKER_USER)
DOCKERHUB_PASSWORD=$(shell cat ${KEYS}/DOCKER_PASS)
DOCKERHUB_ORG=sysdiglabs

# -----------------------------------------------------------------------------

installer-build-image:
	docker build . -f build/Dockerfile -t ${INSTALLER_IMAGE}:dev \
		-t docker push ${INSTALLER_IMAGE}:latest \
		-t docker push ${INSTALLER_IMAGE}:${VERSION_FULL} \
		-t docker push ${INSTALLER_IMAGE}:${VERSION_MAJOR}

installer-push-dev:
	docker push ${INSTALLER_IMAGE}:dev

installer-scan: IMAGE=${INSTALLER_IMAGE}
installer-scan: inline-scan

installer-push: check-shell installer-build-image installer-scan
	docker push ${INSTALLER_IMAGE}:latest
	docker push ${INSTALLER_IMAGE}:${VERSION_FULL}
	docker push ${INSTALLER_IMAGE}:${VERSION_MAJOR}

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

# -----------------------------------------------------------------------------

forwarder-build:
	dotnet build "${FORWARDER_DIR}"/AKSKubeAuditReceiver.sln

forwarder-test: check-yaml check-dotnet

forwarder-build-image:
	docker build ${FORWARDER_DIR} -f ${FORWARDER_DOCKERFILE} \
		-t ${FORWARDER_IMAGE}:latest \
		-t ${FORWARDER_IMAGE}:dev \
		-t ${FORWARDER_IMAGE}:${VERSION_FULL} \
		-t ${FORWARDER_IMAGE}:${VERSION_MAJOR}

forwarder-push-dev:
	docker push ${FORWARDER_IMAGE}:dev

forwarder-scan: IMAGE=${FORWARDER_IMAGE}
forwarder-scan: inline-scan

forwarder-push: forwarder-test forwarder-build-image forwarder-scan
	docker push ${FORWARDER_IMAGE}:latest
	docker push ${FORWARDER_IMAGE}:${VERSION_FULL}
	docker push ${FORWARDER_IMAGE}:${VERSION_MAJOR}

# -----------------------------------------------------------------------------

install:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		sysdiglabs/aks-audit-log-installer:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}

uninstall:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		--entrypoint /app/uninstall-aks-audit-log.sh \
		sysdiglabs/aks-audit-log-installer:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}


# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------

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
