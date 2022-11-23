#/bin/bash -e
USER_FOLDER=$(pwd)

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource $AZ_MANAGEMENT_URI --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

echo "Download Sample notebooks"
mkdir -p notebooks && cd notebooks
curl -L \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/examples/run_importance_chr22_with_hail.ipynb" \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/3ddcad2ec49922030c762757e82ccbabe6a15903/examples/run_importance_chr22.ipynb" \
    -O "https://github.com/aehrc/VariantSpark/blob/master/dev-notebooks/HipsterHailvsVS_covariates.ipynb"
cd $USER_FOLDER

echo "Upload Sample notebooks"
for notebook in notebooks/*.ipynb; do
    filename=$(basename $notebook)
    echo "Upload sample notebook $notebook to workspace"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${ADB_WORKSPACE_URL}/api/2.0/workspace/import \
        --form contents=@"$notebook" \
        --form path="/Shared/$filename" \
        --form format=JUPYTER \
        --form language=PYTHON \
        --form overwrite=true
done

echo "Download Sample Data"
mkdir -p data && cd data
curl -L \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/data/chr22_1000.vcf" \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/data/chr22-labels.csv" \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/data/chr22-labels-hail.csv" \
    -O "https://github.com/aehrc/VariantSpark/raw/master/data/hipsterIndex/hipster.vcf.bgz" \
    -O "https://github.com/aehrc/VariantSpark/raw/master/data/hipsterIndex/hipster_labels_covariates.txt"
    
cd $USER_FOLDER

echo "Upload Sample data"
for file in data/*.*; do
    filename=$(basename $file)
    echo "Upload sample data $file to workspace"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${ADB_WORKSPACE_URL}/api/2.0/dbfs/put \
        --form contents=@"$file" \
        --form path="/databricks/Filestore/$filename" \
        --form overwrite=true
done

echo "Enable Container Services"
curl -sS -X PATCH -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId"         https://${ADB_WORKSPACE_URL}/api/2.0/preview/workspace-conf --data '{"enableDcs": "true" }'
