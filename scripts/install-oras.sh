#!/bin/bash
az artifacts universal download --organization "https://devdiv.visualstudio.com/" --feed "java-engineering-infra" --name "oras_1.1.0_linux_amd64.tar.gz" --version "${ORAS_VERSION}" --path .

if [[ $? -ne 0 ]]; then
  echo "Failed to download oras_${ORAS_VERSION}_*.tar.gz"
  exit 1
fi

mkdir -p oras-install/
tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
sudo mv oras-install/oras /usr/local/bin/
rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/