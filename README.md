# Pre-requisites
  1) Get *contributor* access to target Azure tenant and subscription from your cloud admin team
  2) Get *contributor+userAccessAdministor* or owner access to target managed identity from your cloud admin team
  3) Get *contributor* access to ISAaC GitHub repository from MobiLab ISAaC team

# Fork the ISAaC GitHub Repository
  Fork the ISAaC GitHub repository in your own GitHub workspace
  *Note*: Your organization should compliant with GitHub as valid software

# Add federated credential to managed identity and update it to your GitHub workspace
  Go to  [Microsoft Azure](https://portal.azure.com)  → Search *“managed identity“* in top middle search box → Click the target managed identity → click *“federated credentials (preview)“* in the left pane → Click *“Add credentials”* <br>
  ## Input Parameters:
  - Federated credential scenario - GitHub Actions deploying Azure Resources
  - Organization                  - Enter your GitHub organization/owner name of your choice
  - Repository                    - Enter the URL of the forked repository from above
  - Entity                        - master
  - Name                          - Enter any name of your choice, make it relevant

  Launch the forked GitHub repository → Click “settings” → add the followings secrets one by one with managed identity details <br>
  1) AZURE_CLIENT_ID
  2) AZURE_SUBSCRIPTION_ID
  3) AZURE_TENANT_ID

Reference: 
- [Add federated credential](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust-user-assigned-managed-identity?pivots=identity-wif-mi-methods-azp#configure-a-federated-identity-credential-on-a-user-assigned-managed-identity)
- [Creating GitHub secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)
  
# Configure infrastructure parameters
  Adjust the different parameters inside `common-config.yaml` file in your forked GitHub repository as per the description given below and commit it to master branch
  ```
  ---
    tenantId: "<input tenant or directory id>"
    location: "<input azure region name where azure resources to be created, ex. westeurope>"
    locationAbbreviation: "<input standard azure region abbreviation name corresponding to above location, ex. weu>"
    environment: "<input environment name, ex. prod>"
    workload: "<input workload or short form of team name, ex. ops>"
    org: "<input organisation name, ex. mblb>"
    tags:
      OwnerEmail: "<input owner email id>"
      CreationDate: "<input azure resource creation date>"
      DeletionDate: "<input azure resource deletion date>"
    tfstate:
      # Terraform requires a storage account to store the statefile, those info goes here; either you can create new resources or use the existing one
      resourceGroupName: "<input desired statefile resource group name or already created one, ex. rg-prod-mlb-iac-westeurope>"
      storageAccountName: "<input desired statefile storage account name or already created one, ex. stprodmlbiacopsweu>"
      containerName: "<input desired statefile storage account container name or already created one, ex. tfstate>"
      key: "<input desired terraform state file name, ex. tf-prod-mlb-iac-weu.tfstate>"
      useOidc: true
    #------databricks------#
    databricksConfig:
      sku: "standard"
  ```
  *Note*: The new terraform statefile resources will be created by the pipeline automatically based on your desired input

# Examine the GitHub workflow or pipeline
  Once the common-config.yaml file has been committed, the pipeline will be triggered automatically in your pipeline;
  And examine how the pipeline goes and verify the deployed azure infrastructure in your azure subscription, once pipeline successful.