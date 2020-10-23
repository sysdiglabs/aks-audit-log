
INSTALLER_IMAGE=sysdiglabs/aks-audit-log-installer
INSTALLER_MAYOR=1
INSTALLER_MINOR=1.0

RESOURCE_GROUP="aks-test-group"
CLUSTER_NAME="aks-test-cluster"

installer-build-dev:
	docker build . -t ${INSTALLER_IMAGE}:dev

installer-push-dev:
	docker push ${INSTALLER_IMAGE}:dev

installer-build:
	docker build . -t ${INSTALLER_IMAGE}:latest -t ${INSTALLER_IMAGE}:${INSTALLER_MAYOR} -t ${INSTALLER_IMAGE}:${INSTALLER_MINOR}

installer-push:
	docker push ${INSTALLER_IMAGE}:latest
	docker push ${INSTALLER_IMAGE}:${INSTALLER_MAYOR}
	docker push ${INSTALLER_IMAGE}:${INSTALLER_MINOR}

install:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		sysdiglabs/aks-audit-log-installer:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}

uninstall:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		--entrypoint /app/uninstall-aks-audit-log.sh \
		sysdiglabs/aks-audit-log-installer:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}