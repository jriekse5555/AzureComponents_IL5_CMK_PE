#!/bin/bash

# Define an array of Bicep files and their corresponding output README files
declare -A bicep_files=(
    ["acr/acrDeployCarml.bicep"]="acr/README.md"
    ["aks/aksSystemDeploy.bicep"]="aks/README.md"
    ["keyvault/kvtDeployCarml.bicep"]="keyvault/README.md"
    ["storage/stgDeployCarml.bicep"]="storage/README.md"
)

# Define the sections to include in the documentation
sections="description,modules,parameters,resources,variables,outputs,usage"

# Generate documentation for each Bicep file
for bicep_file in "${!bicep_files[@]}"; 
do
    output_file=${bicep_files[$bicep_file]}
    echo "Generating documentation for $bicep_file..."
    if [[ $bicep_file == *"keyvault"* || $bicep_file == *"storage"* ]]; then
        bicep-docs -i "$PWD/$bicep_file" --output "$PWD/$output_file" --include-sections "${sections%,usage}"
    else
        bicep-docs -i "$PWD/$bicep_file" --output "$PWD/$output_file" --include-sections "$sections"
    fi
    echo "Documentation for $bicep_file generated at $output_file"
done

echo "All documentation has been generated."