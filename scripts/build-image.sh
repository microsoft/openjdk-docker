#!/bin/bash
az acr login -n msopenjdk
docker buildx create --name mybuilder --platform linux/amd64,linux/arm64 --use

if [[ '$DISTRIBUTION' != 'distroless' ]]; then
    BUILD_ARGS="--build-arg IMAGE=$IMAGE --build-arg TAG=$TAG --build-arg package=$PACKAGE"
else
    BUILD_ARGS="--build-arg INSTALLER_IMAGE=$INSTALLER_IMAGE --build-arg INSTALLER_TAG=$INSTALLER_TAG --build-arg BASE_IMAGE=$(base_image) --build-arg BASE_TAG=$(base_tag) --build-arg package=$PACKAGE"
fi

docker buildx build --platform linux/amd64,linux/arm64 ${BUILD_ARGS} -t $REGISTRY_TAG -f docker/$DISTRIBUTION/Dockerfile.$PACKAGE-jdk . --push