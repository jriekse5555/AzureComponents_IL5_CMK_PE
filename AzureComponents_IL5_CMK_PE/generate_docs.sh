bicep-docs -i $PWD/acr/acrDeployCarml.bicep --output $PWD/acr/README.md --exclude-sections usage
bicep-docs -i $PWD/aks/aksSystemDeploy.bicep --output $PWD/aks/README.md
bicep-docs -i $PWD/keyvault/kvtDeployCarml.bicep --output $PWD/keyvault/README.md
bicep-docs -i $PWD/storage/stgDeployCarml.bicep --output $PWD/storage/README.md