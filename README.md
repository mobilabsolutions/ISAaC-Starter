# Pre-requisites to run the CDKTF project

1. Please refer confluence for understanding the prerequisites of using the mobilab cloud platform. Please follow below steps after the prerequisites are completed.

2. Download and install Terraform CLI
      ```
      https://developer.hashicorp.com/terraform/downloads
      ``` 
3. Download and install Node JS
      ```
      https://nodejs.org/en/download
      ``` 
4. Install CDKTF using npm command
      ```
      npm install --global cdktf-cli@0.13.0
      ```
5. Download the remote CDKTF core templates from the public GITHUB repository to local in an empty folder
      ```
      cdktf init --template https://github.com/mobilabsolutions/azure-data-platform-cdktf-templates/archive/refs/tags/v1.0.0.zip --local
      ```
  
# Supply pre-deployment configuration and setup terraform statefile

1. Please refer the sample `common-config.yaml` which is mentioned in the confluence page. Copy the sample `common-config.yaml` file contents. Rename `common-config.yaml.sample` to `common-config.yaml` and update the contents with the required configuration. The values like tenantId, storageAccountName etc are already mentioned in the sample `common-config.yaml` file. These values are good to get started with to create the infrastructure using Mobilab cloud platform. However these values can be changed as per need accordingly.

The significance of each field in the common-config.yaml file is given below :- 

```yaml
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
  key: <input desired terraform state file name, ex. tf-prod-mlb-iac-weu.tfstate>
#------databricks------#
databricksConfig:
  sku: "standard"
 ```
      
# Download required dependencies

Execute below command at the root location of the project :- 

```
npm install
```

# To synthesize and deploy the CDKTF project

  1) Synthesize the CDKTF project at the project root directory
      ```
      cdktf synth
      ```
  2) Deploy the CDKTF project to the Azure cloud
      ```
      cdktf deploy
      ```
      If the CDKTF templates are synthesized successfully the terraform plan is displayed.
      After carefully reviewing the terraform plan, go ahead and approve the plan.
      After approval of terraform plan, the Azure resources will be created in the mentioned
      subscription one by one as per the logical sequence.

# To destroy the created resources
  1) Destroy the above created infrastructure
     - Execute below command at the root location of the project to destroy the abvoe created infrastructure:
      ```
      cdktf destroy
      ```
     After the successfull execution of this command, the terraform plan will be displayed which mentions 
     the resources that would be destroyed. Once the plan is approved the infrastructure will be destroyed.
