#!/bin/bash
#---------------------------------------------------------------------------#
# Author: Karthic Ganesan (MobiLab Solutions GmbH)                          #
# Bash script to create following                                           #
#    [1] IAC resource group within the subscription                         #
#    [2] Storage account within the [1] resource group                      #
#    [3] Container within the [2] storage account                           #
#---------------------------------------------------------------------------#
set -e
set -u

# Exit function
fairExit () {
    if [ ${?} -ne 0 ]; then
	    echo "ERROR: $1."; exit 1
	fi
    return 0
}

# Check AzCLI existance
is_azcli_exist () {
    az --version > /dev/null 2>&1 || fairExit "AzCLI not installed"
    return ${?}
}

# Set variables using common grep
set_var () {
    for i in ${1}; do
            export ${i}=$(grep "${i}" ${target_file} | head -1 | awk -F'"' '{ print $2 }')
    done
}

# Create IAC Resource Group, Storage Account (sa) & sa container, if not exist
iac_stuffs () {
    sub_id=`az account show --query "{subscriptionid:id}" -o tsv`
    az account set --subscription ${sub_id} || fairExit "Unable to get subscription ${sub_id}"
    if [[ $(az group exists -n ${iac_rg}) = false ]]; then
        echo "Creating IAC resource group..."
        az group create -l westeurope -n ${iac_rg} --tags REQUIRED_TAGS || fairExit "Failed to create resourcegroup ${iac_rg}"
    # else
    #    rg_id=`az group show -n ${iac_rg} --query "id" -o tsv`
    #    az tag create --resource-id ${rg_id} --tags REQUIRED_TAGS || fairExit "Failed to update the tags for RG ${iac_rg}"
    #    # az tag update --operation merge --resource-id ${rg_id} --tags REQUIRED_TAGS || fairExit "Failed to update the tags for RG ${iac_rg}"
    fi
    az provider register --namespace Microsoft.Storage # Sometimes, certain subscriptions are not already registered with Storage Az provider
    if [[ $(az storage account check-name -n ${iac_sa} --query {exists:nameAvailable} -o tsv) = True ]]; then
        echo "Creating IAC storage account..."
        az storage account create -n ${iac_sa} --resource-group ${iac_rg} -l ${location} --sku Standard_LRS --tags REQUIRED_TAGS || fairExit "Failed to create storage account ${iac_sa}"
    # else
    #    sa_id=`az storage account show -n ${iac_sa} --query "id" -o tsv`
    #    az tag create --resource-id ${sa_id} --tags REQUIRED_TAGS || fairExit "Failed to update the tags for storage account ${iac_rg}"
    #    # az tag update --operation merge --resource-id ${sa_id} --tags REQUIRED_TAGS || fairExit "Failed to update the tags for storage account ${iac_rg}"
    fi
    az storage account list --resource-group ${iac_rg} | grep ${iac_sa} || fairExit "Storage account ${iac_sa} exist but not at ${iac_rg}"
    sas_end=`date -u -d "20 minutes" '+%Y-%m-%dT%H:%MZ'`
    sas_token=`az storage account generate-sas --permissions cdlruwap --account-name ${iac_sa} --services b --resource-types sco --expiry ${sas_end} -o tsv 2>/dev/null`
    if [ -z "${sas_token}" ]; then
        echo "ERROR: Empty storage account SAS token."; return 1
    else
        echo ${sas_token} > /tmp/sastoken.txt
        if [[ $(az storage container exists --account-name ${iac_sa} --sas-token ${sas_token} --name ${iac_container_name} -o tsv) = False ]]; then
            echo "Creating IAC storage account container..."
            az storage container create -n "tfstate" --account-name ${iac_sa} --sas-token ${sas_token} || fairExit "Failed to create storage account container tfstate"
        fi
    fi
    return ${?}
}

#------#
# MAIN #
#------#
# is_azcli_exist
target_file="common-config.yaml"
set_var "org environment workload location locationAbbreviation resourceGroupName storageAccountName containerName"
iac_rg="${resourceGroupName}"
iac_sa="${storageAccountName}"
iac_container_name="${containerName}"
iac_stuffs || exit 1
echo "Bootstraping done."
exit 0