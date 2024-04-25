#!/bin/bash
az acr login -n msopenjdk

if [[ $? -ne 0 ]]; then
    echo "Failed to login to ACR"
    exit 1
fi

echo "Pulling... $REGISTRY"

docker pull "$REGISTRY"
if [[ $? -ne 0 ]]; then
    echo "Failed to pull image $REGISTRY"
    exit 1
fi

manifest=$(docker image inspect "$REGISTRY" | jq)
digest=$(echo $manifest | jq '.[0].RepoDigests[0]')
digest=${digest//\"/}
endOfLifeDate=$(date "+%Y-%m-%d")

password=$(az acr login --name "$ACR_NAME" --expose-token --output tsv --query accessToken)
echo "Oras login to $ACR_NAME.azurecr.io"
oras login $ACR_NAME.azurecr.io --username "$USER_NAME" --password $password
if [[ $? -ne 0 ]]; then
    echo "Failed to login to container registry"
    exit 1
fi

echo "Annotating image $digest with end-of-life date $endOfLifeDate"
oras attach \
--artifact-type "application/vnd.microsoft.artifact.lifecycle" \
--annotation "vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z" \
$digest --verbose

if [[ $? -ne 0 ]]; then
    echo "Failed to annotate image!"
    exit 1
fi