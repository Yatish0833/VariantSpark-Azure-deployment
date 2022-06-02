#!/usr/bin/env bash

echo "Running Bicep basic deployment file"
bicep_output=$(az deployment group create \
    --resource-group variantdb \
    --template-file basic.bicep \
    --only-show-errors)

if [[ -z "$bicep_output" ]]; then
    echo "Deployment failed, check errors on Azure portal"
    exit 1
fi

echo "$bicep_output" >output.basic.json # save output
echo "Bicep deployment. Done"
