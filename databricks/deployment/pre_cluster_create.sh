#/bin/bash -e
USER_FOLDER=$(pwd)

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

echo "Download init script"
mkdir -p init_scripts && cd init_scripts
curl -L \
    -O "https://raw.githubusercontent.com/krisbock/variant-databricks/main/databricks/init_scripts/library_install.sh"
cd $USER_FOLDER


echo "Upload init script to /databricks/init/library_install.sh"
curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
    https://${ADB_WORKSPACE_URL}/api/2.0/dbfs/put \
    --form contents=@"init_scripts/library_install.sh" \
    --form path="/databricks/init/library_install.sh" \
    --form overwrite=true

## added library 25/05
echo "Download VariantSpark  jar files"
mkdir -p jars && cd jars
curl -L \
    -O "https://raw.githubusercontent.com/krisbock/variant-databricks/main/databricks/jars/variant-spark_2.11-0.5.0-a0-dev0-all.jar" 
cd $USER_FOLDER

echo "Upload jar files"
for jar_file in jars/*.jar; do
    filename=$(basename $jar_file)
    echo "Upload $jar_file file to DBFS path"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${ADB_WORKSPACE_URL}/api/2.0/dbfs/put \
        --form filedata=@"$jar_file" \
        --form path="/FileStore/jars/$filename" \
        --form overwrite=true
done
####

#echo "Install libraries"
#curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
#    https://${ADB_WORKSPACE_URL}/api/2.0/libraries/install \
#    --form contents=@"init_scripts/library-libraries.json" 

echo "Download Sample notebooks"
mkdir -p notebooks && cd notebooks
curl -L \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/examples/run_importance_chr22_with_hail.ipynb" 
# -O "https://raw.githubusercontent.com/krisbock/variant-databricks/main/databricks/notebooks/VariantSpark_example.ipynb" 
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
        --form language=SCALA \
        --form overwrite=true
done

echo "Download Sample Data"
mkdir -p data && cd data
curl -L \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/data/chr22_1000.vcf" \
    -O "https://raw.githubusercontent.com/aehrc/VariantSpark/master/data/chr22-labels-hail.csv"
    
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



