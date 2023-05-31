#!/bin/bash
#---------------------------------------------------------------------------#
# Bash script to create following                                           #
#    [1] IAC resource group within the subscription                         #
#    [2] Storage account within the [1] resource group                      #
#    [3] Container within the [2] storage account                           #
#    [4] Azure Container Registry (ACR) to hold source docker images        #
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

# Set variables using common grep
set_var () {
    for i in ${1}; do
            export ${i}=$(grep "${i}" ${target_file} | head -1 | awk -F'"' '{ print $2 }')
    done
}

# Map location name with it's short name
location_map () {
    case "${1}" in
        "eastus")
            location_short="eus" ;;
        "eastus2")
            location_short="eus2" ;;
        "southcentralus")
            location_short="scus" ;;
        "westus2")
            location_short="wus2" ;;
        "westus3")
            location_short="wus3" ;;
        "australiaeast")
            location_short="ause" ;;
        "southeastasia")
            location_short="seasia" ;;
        "northeurope")
            location_short="neu" ;;
        "swedencentral")
            location_short="swec" ;;
        "uksouth")
            location_short="uks" ;;
        "westeurope")
            location_short="weu" ;;
        "centralus")
            location_short="cus" ;;
        "southafricanorth")
            location_short="san" ;;
        "centralindia")
            location_short="cind" ;;
        "eastasia")
            location_short="easia" ;;
        "japaneast")
            location_short="jape" ;;
        "koreacentral")
            location_short="korc" ;;
        "canadacentral")
            location_short="canc" ;;
        "germanywestcentral")
            location_short="frac" ;;
        "norwayeast")
            location_short="gerwc" ;;
        "switzerlandnorth")
            location_short="norc" ;;
        "uaenorth")
            location_short="swin" ;;
        "brazilsouth")
            location_short="uaen" ;;
        "qatarcentral")
            location_short="bras" ;;
        "asia")
            location_short="asia" ;;
        "asiapacific")
            location_short="asiapac" ;;
        "australia")
            location_short="aus" ;;
        "brazil")
            location_short="bra" ;;
        "canada")
            location_short="can" ;;
        "europe")
            location_short="eu" ;;
        "france")
            location_short="fra" ;;
        "germany")
            location_short="ger" ;;
        "global")
            location_short="glo" ;;
        "india")
            location_short="ind" ;;
        "japan")
            location_short="jap" ;;
        "korea")
            location_short="kor" ;;
        "norway")
            location_short="nor" ;;
        "singapore")
            location_short="sin" ;;
        "southafrica")
            location_short="safr" ;;
        "switzerland")
            location_short="swi" ;;
        "uae")
            location_short="uae" ;;
        "uk")
            location_short="uk" ;;
        "unitedstates")
            location_short="ua" ;;
        "westus")
            location_short="wus" ;;
        "ukwest")
            location_short="uk" ;;
        "*")
            break ;;
    esac
}

# Create IAC Resource Group, Storage Account (sa) & sa container, if not exist
iac_stuffs () {
    sub_id=`az account show --query "{subscriptionid:id}" -o tsv`
    az account set --subscription ${sub_id} || fairExit "Unable to get subscription ${sub_id}"
    if [[ $(az group exists -n ${iac_rg}) = false ]]; then
        echo "Creating IAC resource group..."
        az group create -l ${location} -n ${iac_rg} --tags REQUIRED_TAGS || fairExit "Failed to create resourcegroup ${iac_rg}"
    fi
    az provider register --namespace Microsoft.Storage # Sometimes, certain subscriptions are not already registered with Storage Az provider
    if [[ $(az storage account check-name -n ${iac_sa} --query {exists:nameAvailable} -o tsv) = True ]]; then
        echo "Creating IAC storage account..."
        az storage account create -n ${iac_sa} --resource-group ${iac_rg} -l ${location} --sku Standard_LRS --tags REQUIRED_TAGS || fairExit "Failed to create storage account ${iac_sa}"
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
            az storage container create -n ${iac_container_name} --account-name ${iac_sa} --sas-token ${sas_token} || fairExit "Failed to create storage account container ${iac_container_name}"
        fi
    fi

    if [[ $(az acr check-name -n ${iac_container_registry} --query nameAvailable -o tsv) = true ]]; then
        echo "Creating Azure Container Registry..."
        az acr create --resource-group ${iac_rg} --name ${iac_container_registry} --sku Basic --location ${location} --tags REQUIRED_TAGS || fairExit "Failed to create container registry ${iac_container_registry}"
    fi
    return ${?}
}

#------#
# MAIN #
#------#
target_file="common-config.yaml"
set_var "org environment location resourceGroupName storageAccountName containerName"
iac_rg="${resourceGroupName}"
iac_sa="${storageAccountName}"
iac_container_name="${containerName}"
location_map ${location} || exit 1
workload="dmlz"
component="dpms"
iac_container_registry="acr${org}${environment}${workload}${component}${location_short}"
iac_stuffs || exit 1
echo "Bootstraping done."
exit 0