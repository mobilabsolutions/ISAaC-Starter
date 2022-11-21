# azure-data-platform-cdktf

# How to Install the pre-requisites to run the project.

Below are the steps to install the pre requisites to run the project - 

  1) Download and install Node JS using the below link.

      ```
      https://nodejs.org/en/download/
      ``` 
  2) Install CDKTF by executing the below npm command in the terminal.

     ```
      npm install --global cdktf-cli@latest
     ```
  3) Execute the below command to download the remote template from the GIT repository.
  
  ```
  cdktf init --template https://github.com/mobilabsolutions/azure-data-platform-cdktf-templates --local
  ```
     
  4) Install the required libraries using yarn.

     - cd to the project root directory and execute the below command-
    
     ```
     yarn install
     ```

# Update the common-config.yaml.sample configuration file

  5) Rename this file to common-config.yaml.
  6) Update the content of this configuration file as below 

  ````
  ```
  tenantId: "<enter tenant id here>"
  location: "enter location here"
  locationAbbreviation: "enter local abbrevation here"
  environment: "enter environment here"
  workload: "<enter workload here>"
  org: "<enter org here>"
  tags:
    OwnerEmail: "<enter owners email id>"
    CreationDate: "<enter resource creation date>"
    DeletionDate: "<enter deletion date>"
  tfstate:
    resourceGroupName: "<Terraform requires a storage account to store the state. 
                         Enter the name of resource group here which will have the storage account to hold the terraform state>"
    storageAccountName: "<Enter the storage account name which will store the state of terraform>"
    containerName: "<Enter the name of the container inside the storage account which will hold the terraform state>"
    key: <key>

  ```
  ````       

# How to synthesize and deploy the project.

  7) Synthesize the code by executing the below command at the project root directory
     ```
      cdktf synth
     ```
  8) Deploy the templates to the cloud.

     - Login to Microsoft Azure with the appropriate tenant id using below command 
     ```
     az login --tenant <tenand-id>
     ```
     - Set the appropriate subscription id using below command.
     ```
     az account set --subscription '<subscription-id>'
     ```

     Execute below command in the terminal to set the environment variable ARM_ACCESS_KEY

     ```
     $env:ARM_ACCESS_KEY=$(az storage account keys list -g <resource group name> -n <storage account name> --query "[0].value" -o tsv)  
     ``` 

     - Execute the command to deploy templates to the mentioned subscription and tenant
     ```
     cdktf deploy
     ```
     After this command is executed, if the templates are synthesized successfully the terraform 
     plan is displayed. After carefully reviewing the terraform plan if it is as per expectations.
     Then Approve the plan. After the approval of terraform plan the resources will be created in 
     the mentioned subscription one by one as per the logical sequence.

# How to destroy the created resources 

  9) Destroy the created infrastructure in the cloud.
     
     - Execute below command at the root location of the project to destroy the terraform infrastructure
     ```
     cdktf destroy
     ```
     After the successfull execution of this command, the terraform plan will be displayed which mentions 
     the resources that would be destroyed. Once the plan is approved the infrastructure is destroyed. 

   



