# Pre-requisites to run the CDKTF project
  1) Download and install Node JS
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
  5) Setup the Terraform state file
     - Login to Microsoft Azure with the target tenant id
      ```
      az login --tenant <tenand-id>
      ```
     - Set the target Azure subscription id
      ```
      az account set --subscription '<subscription-id>'
      ```
     - Create separate resource group, storage account and container to store the CDKTF state file
      ```
      az group create --location <location> --name <rg name> --tage <list of tags using NAME="VALUE" pairs>
      ```
      ```
      az storage account create --name <storage account name> -g <above rg name> --location <location> --sku "Standard_LRS" --tags <list of tags using NAME="VALUE" pairs>
      ```
      ```
      $env:ARM_ACCESS_KEY=$(az storage account keys list -g <above rg name> -n <above storage account name> --query "[0].value" -o tsv) ---> At PowerShell
      export ARM_ACCESS_KEY=$(az storage account keys list -g <above rg name> --name <above storage account name> --query "[0].value" -o tsv ) ---> At GitBash
      ```
      ```
      az storage container create --name <storage container name> --account-name <above storage account name> --account-key $ARM_ACCESS_KEY
      ```
     - TODO: Create default subnet in your VNet, if not already
  6) Rename common-config.yaml.sample to common-config.yaml and update the contends with below configuration:
      ```
      tenantId: "<enter tenant id here>"
      location: "<enter Azure region here>"
      locationAbbreviation: "<enter local abbrevation here>"
      environment: "<enter environment name here>"
      workload: "<enter workload name here>"
      org: "<enter organisation name here>"
      tags:
        OwnerEmail: "<enter owners email id>"
        CreationDate: "<enter resource creation date>"
        DeletionDate: "<enter deletion date>"
      tfstate:
        # Terraform requires a storage account to store the state
        resourceGroupName: "<above rg name from step 3>"
        storageAccountName: "<above storage account name from step 3>"
        containerName: "<above storage account container from step 3>"
        key: <enter the terraform state file name here as per your wish>
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
