data "azurerm_client_config" "current" {}
locals {
  org                   = "sag"
  env                   = "dev"
  location              = "westeurope"
  location_abbrv        = "weu"
  workload              = "coupa"
  vnet_subscription_id  = data.azurerm_client_config.current.subscription_id
  vnet_rg               = "rg-prod-sag-network-westeurope"
  vnet_name             = "vnet-prod-sag-dataplatformcoupaprod-westeurope"
  vnet_id               = "/subscriptions/${local.vnet_subscription_id}/resourceGroups/${local.vnet_rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}"
  default_subnet        = "default"
  default_subnet_prefix = "10.46.114.0/27"
  default_subnet_id     = "${local.vnet_id}/subnets/${local.default_subnet}"

  # Diagonostics logging
  law_subscription_id = local.vnet_subscription_id
  law_rg              = "rg-prod-sag-monitor-westeurope"
  law_name            = "log-prod-sag-monitor-westeurope"
  law_id              = "/subscriptions/${local.law_subscription_id}/resourceGroups/${local.law_rg}/providers/Microsoft.OperationalInsights/workspaces/${local.law_name}"

  # Only for databricks (online) connected
  azuredatabricks_oid = "4085b281-4daa-41ca-b26b-b7ee46f1b2a8"
  vnet_address_prefix = "10.46"

  # Verify below tag key value pairs are compatible with overall azure policies
  tags = {
    BusinessCriticality = "BusinessOperational"
    CostCenter          = "10404604"
    CreationDate        = "20.10.2022"
    DataSensitivity     = "Confidential"
    Environment         = "Dev"
    ManagedBy           = "Data Platforms and Analytics"
    Owner               = "Mario Gross"
    OwnerEmail          = "mario.gross@sartorius.com"
  }
}

# Provisioning Data Lake Storage in cnline-connected Landing Zone
module "data_lake_storage_online_connected" {
  source = "git::https://sartorius-sca@dev.azure.com/sartorius-sca/dsm_dpa-dataplatform/_git/iac-molecules//data_lake_storage_online_connected?ref=0.1.0"

  org                                = local.org
  environment                        = local.env
  workload                           = local.workload
  location                           = local.location
  location_abbreviation              = local.location_abbrv
  account_replication_type           = "LRS"
  account_tier                       = "Standard"
  sa_public_network_access_enabled   = false # Dis-allow main storage account public access
  sa_allow_nested_items_to_be_public = false # Dis-allow Blob public access (Anonymous)
  log_analytics_workspace_id         = local.law_id
  subnet_id                          = local.default_subnet_id
  dls_pe_instances = [
    {
      subtype                           = ["blob"]
      dls_private_dns_zone_link_with_pe = null
    },
    #     {
    #       subtype                           = ["table"]
    #       dls_private_dns_zone_link_with_pe = null
    #     },
    #    {
    #      subtype                           = ["queue"]
    #      dls_private_dns_zone_link_with_pe = null
    #     },
    {
      subtype                           = ["file"]
      dls_private_dns_zone_link_with_pe = null
    },
    #    {
    #       subtype                           = ["web"]
    #       dls_private_dns_zone_link_with_pe = null
    #     },
    {
      subtype                           = ["dfs"]
      dls_private_dns_zone_link_with_pe = null
    }
  ]
  tags = local.tags
}

# Provisioning Data Factory in online-connected Landing Zone
module "data_factory_online_connected" {
  source = "git::https://sartorius-sca@dev.azure.com/sartorius-sca/dsm_dpa-dataplatform/_git/iac-molecules//data_factory_online_connected?ref=0.1.0"

  org                        = local.org
  environment                = local.env
  workload                   = local.workload
  location                   = local.location
  location_abbreviation      = local.location_abbrv
  log_analytics_workspace_id = local.law_id
  adf_public_network_enabled = false # Dis-allow ADF public access
  subnet_id                  = local.default_subnet_id
  # adf_private_dns_zone_link_with_pe = ({
  #   name                     = "pez-${local.env}-${local.org}-adf-${local.workload}-${local.location}"
  #   private_dns_zone_ids     = null
  # })
  # adfkv_private_dns_zone_link_with_pe = ({
  #   name                     = "pez-${local.env}-${local.org}-adf-${local.workload}-kv-${local.location}"
  #   private_dns_zone_ids     = null
  # })
  tags = local.tags
}

# # Provisioning Databricks in connected Landing Zone
module "databricks_online_connected" {
  source = "git::https://sartorius-sca@dev.azure.com/sartorius-sca/dsm_dpa-dataplatform/_git/iac-molecules//data_bricks_online_connected?ref=0.1.0"

  org                                   = local.org
  environment                           = local.env
  workload                              = local.workload
  azuredatabricks_oid                   = local.azuredatabricks_oid
  location                              = local.location
  location_abbreviation                 = local.location_abbrv
  log_analytics_workspace_id            = local.law_id
  subnet_id                             = local.default_subnet_id
  vnet_rg                               = local.vnet_rg
  vnet_name                             = local.vnet_name
  virtual_network_id                    = local.vnet_id
  vnet_address_prefix                   = local.vnet_address_prefix
  databricks_sku                        = "premium"
  dbw_public_network_access_enabled     = true # Allow/Dis-allow databricks workspace, databricks keyvault & databricks storage account public accesses
  #network_security_group_rules_required = "NoAzureDatabricksRules"  # This line can be commented out, if "dbw_public_network_access_enabled" is true
  subnet_instances = [
    {
      name             = "public"
      address_prefixes = "10.46.116.0/26"
    },
    {
      name             = "private"
      address_prefixes = "10.46.116.64/26"
    }
  ]
  # dbw_private_dns_zone_link_with_pe = ({
  #   name                     = "pez-${local.env}-${local.org}-dbw-${local.workload}-${local.location}"
  #   private_dns_zone_ids     = [local.dbw_api_private_dns_zone_id]
  # })
  # dbwkv_private_dns_zone_link_with_pe = ({
  #   name                 = "pez-${local.env}-${local.org}-dbw-${local.workload}-kv-${local.location}"
  #   private_dns_zone_ids = [local.kv_private_dns_zone_id]
  # })
  dbwdls_pe_instances = [
    {
      subtype                              = ["blob"]
      dbwdls_private_dns_zone_link_with_pe = null
    }
  ]
  tags = local.tags
}
