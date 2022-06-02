#/bin/bash -e

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

libraries='[
        {
                "jar": "dbfs:/FileStore/jars/variant-spark_2.11-0.5.0-a0-dev0-all.jar"
        },
        {
            "maven": {
                "coordinates": "com.databricks.labs:overwatch_2.12:0.4.13"
            }
        },
        {
            "maven": {
                "coordinates": "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.18"
            }
        },
        {
            "maven": {
                "coordinates": "au.csiro.aehrc.variant-spark:variant-spark_2.11:0.0.2-SNAPSHOT",
                "repo": "https://oss.sonatype.org/content/repositories/snapshots"
            }
        },        
        {
            "pypi": {
            "package": "Sphinx==3.3.1",
            "repo": "https://my-pypi-mirror.com"
            }
        },
        {
            "pypi": {
            "package": "sphinx-rtd-theme==0.5.0",
            "repo": "https://my-pypi-mirror.com"
            }
        },
        {
            "pypi": {
            "package": "nbsphinx==0.8.0",
            "repo": "https://my-pypi-mirror.com"
            }
        },
        {
            "pypi": {
            "package": "pylint==2.6.0",
            "repo": "https://my-pypi-mirror.com"
            }
        }, 
        {
            "pypi": {
            "package": "pytest==6.2.2",
            "repo": "https://my-pypi-mirror.com"
            }
        },
        {
            "pypi": {
            "package": "twine==3.2.0",
            "repo": "https://my-pypi-mirror.com"
            }
        },    
        {
            "pypi": {
            "package": "pandas==1.1.4",
            "repo": "https://my-pypi-mirror.com"
            }
        },
        {
            "pypi": {
            "package": "typedecorator==0.0.5",
            "repo": "https://my-pypi-mirror.com"
            }
        },   
        {
            "pypi": {
            "package": "Jinja2==3.0.3",
            "repo": "https://my-pypi-mirror.com"
            }
        },
        {
            "pypi": {
            "package": "hail==0.2.74",
            "repo": "https://my-pypi-mirror.com"
            }
        },   
        {
            "pypi": {
            "package": "variant-spark",
            "repo": "https://my-pypi-mirror.com"
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

# echo "Create Overwatch Job"
# JOB_CREATE_JSON_STRING=$(jq -n -c \
#     --arg ci "$cluster_id" \
#     '{name: "overwatch-job",
#                     existing_cluster_id: $ci,
#                     notebook_task: {
#                     "notebook_path": "/Shared/azure_runner_docs_example.ipynb"
#                                     }
#                     }')
# create_notebook_job=$(echo $JOB_CREATE_JSON_STRING | d_curl "https://${adbWorkspaceUrl}/api/2.0/jobs/create")
# echo $create_notebook_job

echo "Configuring services done"
