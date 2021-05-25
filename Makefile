VERSION_TAG=$(shell git describe --tags $(git rev-list --tags --max-count=1))
VERSION_MAJOR=$(shell echo "${VERSION_TAG}"  | sed 's/[^0-9]*\([0-9]\+.*\)/\1/' )
VERSION_FULL=$(shell echo "${VERSION_TAG}"   | sed 's/[^0-9]*\([0-9]\+\).*/\1/' )

INSTALLER_IMAGE=aks-audit-log-installer
INSTALLER_DIR=./
INSTALLER_DESC=${INSTALLER_DIR}/build/README.md
INSTALLER_DOCKERFILE=${INSTALLER_DIR}/build/Dockerfile

FORWARDER_IMAGE=aks-audit-log-forwarder
FORWARDER_DIR=./AKSKubeAuditReceiverSolution
FORWARDER_DESC=${FORWARDER_DIR}/AKSKubeAuditReceiver/README.md
FORWARDER_DOCKERFILE=${FORWARDER_DIR}/AKSKubeAuditReceiver/Dockerfile

DOCKERHUB_USERNAME=$(shell cat ${KEYS}/DOCKER_USER)
DOCKERHUB_PASSWORD=$(shell cat ${KEYS}/DOCKER_PASS)
DOCKERHUB_ORG=sysdiglabs

GITHUB_USER=$(shell cat ${KEYS}/GH_USER)
GITHUB_PAT_PATH="${KEYS}/GH_PAT_PKG"
GITHUB_REPO=sysdiglabs/aks-audit-log

RESOURCE_GROUP="aks-test-group"
CLUSTER_NAME="aks-test-cluster"

SYSDIG_SECURE_API_TOKEN=$(shell cat ${KEYS}/SYSDIG_SECURE_API_TOKEN)

# -----------------------------------------------------------------------------

installer-build-image: IMAGE_DIR=${INSTALLER_DIR}
installer-build-image: IMAGE_DOCKERFILE=${INSTALLER_DOCKERFILE}
installer-build-image: IMAGE=${DOCKERHUB_ORG}/${INSTALLER_IMAGE}
installer-build-image: build-image

installer-build-push-dev:
	docker build ${INSTALLER_DIR} -f ${INSTALLER_DOCKERFILE} -t ${DOCKERHUB_ORG}/${INSTALLER_IMAGE}:dev
	docker push ${DOCKERHUB_ORG}/${INSTALLER_IMAGE}:dev

installer-scan: IMAGE=${DOCKERHUB_ORG}/${INSTALLER_IMAGE}
installer-scan: inline-scan

installer-dockerhub-readme: IMAGE=${DOCKERHUB_ORG}/${INSTALLER_IMAGE}
installer-dockerhub-readme: DESC_PATH=${INSTALLER_DESC}
installer-dockerhub-readme: update-dockerhub-readme

installer-push: IMAGE=${DOCKERHUB_ORG}/${INSTALLER_IMAGE}
installer-push: check-shell installer-build-image installer-scan push

installer-gh-pkg-release: IMAGE_NAME=${INSTALLER_IMAGE}
installer-gh-pkg-release: check-shell installer-build-image installer-scan gh-pkg-release

# -----------------------------------------------------------------------------

forwarder-build:
	dotnet build "${FORWARDER_DIR}"/AKSKubeAuditReceiver.sln

forwarder-test: check-yaml check-dotnet

forwarder-build-image: IMAGE_DIR=${FORWARDER_DIR}
forwarder-build-image: IMAGE_DOCKERFILE=${FORWARDER_DOCKERFILE}
forwarder-build-image: IMAGE=${DOCKERHUB_ORG}/${FORWARDER_IMAGE}
forwarder-build-image: build-image

forwarder-build-push-dev:
	docker build ${FORWARDER_DIR} -f ${FORWARDER_DOCKERFILE} -t ${DOCKERHUB_ORG}/${FORWARDER_IMAGE}:dev
	docker push ${DOCKERHUB_ORG}/${FORWARDER_IMAGE}:dev

forwarder-scan: IMAGE=${FORWARDER_IMAGE}
forwarder-scan: inline-scan

forwarder-dockerhub-readme: IMAGE=${DOCKERHUB_ORG}/${FORWARDER_IMAGE}
forwarder-dockerhub-readme: DESC_PATH=${FORWARDER_DESC}
forwarder-dockerhub-readme: update-dockerhub-readme

forwarder-push: IMAGE=${DOCKERHUB_ORG}/${FORWARDER_IMAGE}
forwarder-push: forwarder-test forwarder-build forwarder-build-image forwarder-scan push

forwarder-gh-pkg-release: IMAGE_NAME=${FORWARDER_IMAGE}
forwarder-gh-pkg-release: fowarder-test forwarder-build forwarder-build-image forwarder-scan gh-pkg-release

# -----------------------------------------------------------------------------

install:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		${DOCKERHUB_ORG}/${INSTALLER_IMAGE}:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}

uninstall:
	docker run -it -v ${HOME}/.azure:/root/.azure \
		--entrypoint /app/uninstall-aks-audit-log.sh \
		${DOCKERHUB_ORG}/${INSTALLER_IMAGE}:${MINOR} \
		-g ${RESOURCE_GROUP} -c ${CLUSTER_NAME}

# -----------------------------------------------------------------------------

check: check-shell check-yaml check-dotnet

check-shell:
	docker run -v "$$PWD:/mnt" koalaman/shellcheck *.sh

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

build: forwarder-build

# -----------------------------------------------------------------------------

test-gh-actions:
	@if [ -z "$$(command -v act)" ]; then echo "Requires act command installed" ; exit -1 ; fi
	@bash -c "act release -n -e ./test/test-gh-event.json 2> >(tee /tmp/gh-actions-errors.log >&2)" ; \
	if [ -s /tmp/gh-actions-errors.log ]; then \
		cat /tmp/gh-actions-errors.log ; \
		echo "> Errors found"; \
		exit -1; \
	fi ; \
	echo "> No errors on release event workflows"

all-tests: check build test-gh-actions

# -----------------------------------------------------------------------------

show-version:
	@echo "Version tag: ${VERSION_TAG}"
	@echo "Version full: ${VERSION_FULL}"
	@echo "Version major: ${VERSION_MAJOR}"

build-image:
	docker build ${IMAGE_DIR} -f ${IMAGE_DOCKERFILE} \
		-t ${DOCKERHUB_ORG}/${IMAGE}:latest \
		-t ${DOCKERHUB_ORG}/${IMAGE}:dev \
		-t ${DOCKERHUB_ORG}/${IMAGE}:${VERSION_FULL} \
		-t ${DOCKERHUB_ORG}/${IMAGE}:${VERSION_MAJOR}

push:
	docker push ${DOCKERHUB_ORG}/${IMAGE}:latest
	docker push ${DOCKERHUB_ORG}/${IMAGE}:${VERSION_FULL}
	docker push ${DOCKERHUB_ORG}/${IMAGE}:${VERSION_MAJOR}

update-dockerhub-readme-docker:
	echo 'Updating Dockerhub description' ; \
	echo 'Readme: ${DESC_PATH}' ; \
	echo 'Repository: ${IMAGE}' ; \
	docker run -v ${DESC_PATH}:/workspace/README.md \
		-e DOCKERHUB_USERNAME='${DOCKERHUB_USERNAME}' \
		-e DOCKERHUB_PASSWORD='${DOCKERHUB_PASSWORD}' \
		-e DOCKERHUB_REPOSITORY='${IMAGE}' \
		-e README_FILEPATH='/workspace/README.md' \
		peterevans/dockerhub-description:2

update-dockerhub-readme:
	@TOKEN=$$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${DOCKERHUB_USERNAME}'", "password": "'${DOCKERHUB_PASSWORD}'"}' \
    	https://hub.docker.com/v2/users/login/ | jq -r .token) && \
	CODE=$$(jq -n --arg msg "$$(<${DESC_PATH})" '{"full_description": $$msg }' | \
		curl -s -o /dev/null  -L -w "%{http_code}" \
			https://hub.docker.com/v2/repositories/${IMAGE}/ \
			-d @- -X PATCH \
			-H "Content-Type: application/json" \
			-H "Authorization: JWT $${TOKEN}" \
  	) ; \
	if [ "$${CODE}" = "200" ]; then \
    	printf "Successfully updated Docker Hub description" ;\
  	else \
    	printf "Unable to updated Docker Hub description, response code: %s\n" "$${CODE}" ; \
    	exit 1 ; \
  	fi \

gh-pkg-release:
	cat ${GITHUB_PAT_PATH} | docker login https://docker.pkg.github.com -u ${GITHUB_USER} --password-stdin
	docker build . -f build/Dockerfile -t docker.pkg.github.com/${GITHUB_REPO}/${IMAGE_NAME}:${VERSION_FULL}
	docker push docker.pkg.github.com/${GITHUB_REPO}/${IMAGE_NAME}:${VERSION_FULL}

UNAME := $(shell uname)
inline-scan:
	if [ "${UNAME}"=="Darwin" ]; then DOCKER_USER="-u 0"; else DOCKER_USER=""; fi ; \
	docker run $$DOCKER_USER --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		quay.io/sysdig/secure-inline-scan:2 \
		--sysdig-url https://secure.sysdig.com \
		--sysdig-token "${SYSDIG_SECURE_API_TOKEN}" \
		--storage-type docker-daemon \
		--storage-path /var/run/docker.sock \
		${IMAGE} ; \
	RESULT=$$? ; \
	echo ; echo "******************************" ; \
	[ "$$RESULT" -eq 0 ] && echo "** Scan result  > PASS <    **" ; \
	[ "$$RESULT" -eq 1 ] && echo "** Scan result  > FAIL <    **" ; \
	[ "$$RESULT" -eq 2 ] && echo "** Wrong script invokation  **" ; \
	[ "$$RESULT" -eq 3 ] && echo "** Runtime error            **" ; \
	echo "******************************" ; echo ; exit $$RESULT
