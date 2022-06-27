#/bin/bash -e

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

libraries='[
        {
            "maven": {
                "coordinates": "au.csiro.aehrc.variant-spark:variant-spark_2.11:0.4.0"
            }
        },        
        {
            "pypi": {
            "package": "hail==0.2.74"
            }
        },   
        {
            "pypi": {
            "package": "variant-spark"
            }
        }            
    ]'

library_config=$(
    jq -n -c \
        --arg aci "$ADB_CLUSTER_ID" \
        --arg li "$libraries" \
        '{
      cluster_id: $aci,
      libraries: ($li|fromjson)
  }'
)

json=$(echo $library_config | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/libraries/install")

echo "$json" >"$AZ_SCRIPTS_OUTPUT_PATH"

echo "Configuring services done"
