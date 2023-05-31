// This main.ts is for DLZ-LakeHouse
import { Construct } from "constructs";
import { App, AzurermBackend, TerraformStack } from "cdktf";
import { AzurermProvider } from "@cdktf/provider-azurerm/lib/provider";
import { AdpCommonConfig, DefaultNaming } from "adp/common";
import { HttpProvider } from "@cdktf/provider-http/lib/provider";
import { AzureadProvider } from "@cdktf/provider-azuread/lib/provider";
import { RandomProvider } from "@cdktf/provider-random/lib/provider";
import { load } from "js-yaml";
import { readFileSync } from "fs";
import { AdpPrivateLakehouse } from "adp/organisms/adp-private-lakehouse";
import { TimeProvider } from "@cdktf/provider-time/lib/provider";
import { ResourceGroup } from "@cdktf/provider-azurerm/lib/resource-group";
//@ts-ignore
import {RoleAssignment} from "@cdktf/provider-azurerm/lib/role-assignment";

export class ADPStack extends TerraformStack {

  static readonly COMMON_CONFIG_FILE = "common-config.yaml";
  static readonly UTF8_ENCODING: "utf8";

  constructor(scope: Construct, name: string) {
    super(scope, name);

    new AzurermProvider(this, "AzureRm", {
      features: {
        resourceGroup: {
          preventDeletionIfContainsResources: false
        },
        keyVault: {
          recoverSoftDeletedKeyVaults: false,
          purgeSoftDeleteOnDestroy: true
        }
      },
    });

    new HttpProvider(this, "Http");

    new AzureadProvider(this, "AzureAD");

    new RandomProvider(this, "Random");

    new TimeProvider(this, "Time");

    const commonConfig = load(readFileSync(ADPStack.COMMON_CONFIG_FILE, ADPStack.UTF8_ENCODING)) as AdpCommonConfig;

    new AzurermBackend(this, {
      ...commonConfig.tfstate,
      subscriptionId: "33424ac3-8b4d-499b-a4eb-4835038029b2" // DMLZ subscription id
    });

    const naming = new DefaultNaming();

    const hub = {
      resourceGroupName: "rg-mblb-dev-phub-cps-neu",
      vnetName: "vnet-mblb-dev-phub-cps-neu",
      subscriptionId: "33424ac3-8b4d-499b-a4eb-4835038029b2"
    }

    const dlzCpsVnet = {
      name: "vnet-mblb-dev-dlz-di-cps-neu",
      resourceGroupName: "rg-mblb-dev-dlz-di-cps-neu",
      addressSpacePrefix: "10.67.0",
      id: "/subscriptions/bf34a2a9-7f5f-4d14-b6e9-ebb98711dd78/resourceGroups/rg-mblb-dev-dlz-di-cps-neu/providers/Microsoft.Network/virtualNetworks/vnet-mblb-dev-dlz-di-cps-neu"
    };

    const dlzDpaResourceGroup = new ResourceGroup(this, `rg-${commonConfig.workload}-dpa`, {
      ...commonConfig,
      name: naming.getName(ResourceGroup.tfResourceType, commonConfig, "dpa"),
      location: commonConfig.location
    })

    // Uncomment once the datafactory inside lakehouse is created
    const roleAssignments: Map<string, string[]> = new Map<string, string[]>([
      ['Contributor', ['6c129279-b1e4-49c0-803b-678a8ba4ef09']], // DLZ ADF identity
    ]);

    roleAssignments.forEach((principalIds, role) => {
      principalIds.forEach(principalId => {
        new RoleAssignment(this, `role-assignment-${principalId}-${role.replace(/\s/g, "")}`, {
          scope: dlzDpaResourceGroup.id,
          roleDefinitionName: role,
          principalId: principalId
        })
      });
    });

    new AdpPrivateLakehouse(this, {
      ...commonConfig,
      component: "dpa", // Data Platform Applications
      resourceGroupName: dlzDpaResourceGroup.name,

      vnet: {
        name: dlzCpsVnet.name,
        addressSpace: dlzCpsVnet.addressSpacePrefix,
        resourceGroupName: dlzCpsVnet.resourceGroupName,
        id: dlzCpsVnet.id
      },

      // dbwCluster: {
      //   clusterName: "databricks_cluster",
      //   numWorkerNode: 0,
      //   nodeTypeId: "Standard_DS3_v2",
      //   autoterminationMinutes: 10,
      //   sparkVersion: "11.3.x-scala2.12",
      //   dataSecurityMode: "NONE"
      // },

      // dbwClusterLibrary: {
      //   source: {
      //       names: ["pypi","pypi","pypi","maven"],
      //       packages: ["sagemaker-pyspark==1.4.5","pydeequ==1.0.1","pytest==7.2.2","com.amazon.deequ:deequ:2.0.3-spark-3.3"]
      //   },
      //   // type: {
      //   //     names: ["jar", "egg"],
      //   //     path: "/tmp/dummy/"
      //   // },          
      // },

      // dbwSqlWarehouse: {
      //   name: "test-sqlwarehouse",
      //   clusterSize: "2X-Small",
      //   maxNumClusters: 1,
      //   autoStopMins: 10,
      //   warehouseType: "CLASSIC"
      // },

      privateEndpoints: {
        azureDataFactory: {
          privateDnsZoneIds: [`/subscriptions/${hub.subscriptionId}/resourceGroups/${hub.resourceGroupName}/providers/Microsoft.Network/privateDnsZones/privatelink.datafactory.azure.net`],
          subresourceNames: ["dataFactory"]
        },

        azureDatabricks: {
          privateDnsZoneIds: [`/subscriptions/${hub.subscriptionId}/resourceGroups/${hub.resourceGroupName}/providers/Microsoft.Network/privateDnsZones/privatelink.azuredatabricks.net`],
          subresourceNames: ["databricks_ui_api"],
        },

        keyVault: {
          privateDnsZoneIds: [`/subscriptions/${hub.subscriptionId}/resourceGroups/${hub.resourceGroupName}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net`],
          subresourceNames: ["vault"]
        },
      },

      storageAccountDfsEndpoint: "https://samblbdevdmlzdpaneu.dfs.core.windows.net/", //DMLZ central ADLS

      // ADGroups: {
      //   adminADGroup: {
      //     principalIds: [""]
      //   },
      //   contributorGroup: {
      //     principalIds: [""]
      //   }
      // }

    },
    naming);
  };
}

const app = new App();
new ADPStack(app, "adp");
app.synth();