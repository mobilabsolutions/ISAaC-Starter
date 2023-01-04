# Pre-requisites to run the CDKTF project
  1) Download and install Terraform CLI
      ```
      https://developer.hashicorp.com/terraform/downloads
      ``` 
  2) Download and install Node JS
      ```
      https://nodejs.org/en/download
      ``` 
  3) Download the remote CDKTF core templates from the public GITHUB repository to local
      ```
      cdktf init --template https://github.com/mobilabsolutions/azure-data-platform-cdktf-templates/archive/refs/heads/main.zip --local
      ```
  4) Install CDKTF using npm command
      ```
      npm install --global cdktf-cli@latest
      ```
  
# Supply pre-deployment configuration and setup terraform statefile
  1) Rename *common-config.yaml.sample* to *common-config.yaml* and update the contends with required configuration:
      ```
      tenantId: "<input tenant or directory id; refer https://mobilab.atlassian.net/wiki/spaces/CDKTF/pages/5153325415/To+get+Azure+Tenant+and+Subscription+IDs>"
      location: "<input azure region name where azure resources to be created, ex. westeurope>"
      locationAbbreviation: "<input standard azure region abbreviation name corresponding to above location, ex. weu>"
      environment: "<input environment name, ex. prod>"
      workload: "<input workload or short form of team name, ex. ops>"
      org: "<input organisation name, ex. mlb>"
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
  2) Crate terraform statefile resource group, storage account and container
     - Login to Microsoft Azure with the target tenant and subscription ids
      ```
      az login --tenant <tenand-id>
      az account set --subscription=<subscription-id>
      ```
       Refer https://mobilab.atlassian.net/wiki/spaces/CDKTF/pages/5153325415/To+get+Azure+Tenant+and+Subscription+IDs to get tenant and subscription ids
     - Execute set_tags.sh shell script using Git Bash
      ```
      ./set_tags.sh
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
