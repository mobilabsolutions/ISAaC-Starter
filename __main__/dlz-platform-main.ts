// This main.ts is for DLZ-Platform
import { Construct } from "constructs";
import { App, AzurermBackend, TerraformStack, TerraformOutput } from "cdktf";
import { AzurermProvider } from "@cdktf/provider-azurerm/lib/provider";
import { AdpCommonConfig, DefaultNaming } from "adp/common";
import { HttpProvider } from "@cdktf/provider-http/lib/provider";
import { AzureadProvider } from "@cdktf/provider-azuread/lib/provider";
import { RandomProvider } from "@cdktf/provider-random/lib/provider";
import { load } from "js-yaml";
import { readFileSync } from "fs";
import { TimeProvider } from "@cdktf/provider-time/lib/provider";
import { ResourceGroup } from "@cdktf/provider-azurerm/lib/resource-group";
import { VirtualNetwork } from "@cdktf/provider-azurerm/lib/virtual-network";
import { VirtualNetworkPeering } from "@cdktf/provider-azurerm/lib/virtual-network-peering";
//@ts-ignore
import { AdpShirAdf } from "adp/molecules/adp-shir-adf";
//@ts-ignore
import { DataAzurermKeyVaultSecret } from "@cdktf/provider-azurerm/lib/data-azurerm-key-vault-secret";
import { PublicIp } from "@cdktf/provider-azurerm/lib/public-ip";
import { NatGateway } from "@cdktf/provider-azurerm/lib/nat-gateway";
import { NatGatewayPublicIpAssociation } from "@cdktf/provider-azurerm/lib/nat-gateway-public-ip-association";

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

    const dmlzCps = {
      resourceGroupName: "rg-mblb-dev-dmlz-cps-neu",
      vnetName: "vnet-mblb-dev-dmlz-cps-neu",
      subscriptionId: "33424ac3-8b4d-499b-a4eb-4835038029b2"
    }
    
    const dlzVnetAddressSpacePrefix = "10.67.0"

    //Creating a new resource group and vnet for dlz
    //@ts-ignore
    const dlzDpsResourceGroup = new ResourceGroup(this, `rg-${commonConfig.workload}-dps`, {
      ...commonConfig,
      name: naming.getName(ResourceGroup.tfResourceType, commonConfig, "dps"),
      location: commonConfig.location
    })

    const dlzCpsResourceGroup = new ResourceGroup(this, `rg-${commonConfig.workload}-cps`, {
      ...commonConfig,
      name: naming.getName(ResourceGroup.tfResourceType, commonConfig, "cps"),
      location: commonConfig.location
    })

    //@ts-ignore
    const dlzCpsVnet = new VirtualNetwork(this, `vnet-${commonConfig.workload}-cps`, {
      ...commonConfig,
      name: naming.getName(VirtualNetwork.tfResourceType, commonConfig, "cps"),
      location: commonConfig.location,
      addressSpace: [`${dlzVnetAddressSpacePrefix}.0/24`],
      resourceGroupName: dlzCpsResourceGroup.name,
      dnsServers: [`10.65.0.36`]
    })

    new VirtualNetworkPeering(this, `peering-dlzCps-hub`, {
      ...commonConfig,
      name: `peering-dlzCps-hub`,
      resourceGroupName: dlzCpsVnet.resourceGroupName,
      virtualNetworkName: dlzCpsVnet.name,
      remoteVirtualNetworkId: `/subscriptions/${hub.subscriptionId}/resourceGroups/${hub.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${hub.vnetName}`,
      allowGatewayTransit: true,
      allowForwardedTraffic: true,
      useRemoteGateways: true
    });

    new VirtualNetworkPeering(this, `peering-dlzCps-dmlzCps`, {
      ...commonConfig,
      name: `peering-dlzCps-dmlzCps`,
      resourceGroupName: dlzCpsVnet.resourceGroupName,
      virtualNetworkName: dlzCpsVnet.name,
      remoteVirtualNetworkId: `/subscriptions/${dmlzCps.subscriptionId}/resourceGroups/${dmlzCps.resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${dmlzCps.vnetName}`,
      allowGatewayTransit: true,
      allowForwardedTraffic: true
    });

    const dlzCpsShirSubnetName = "snet-mblb-dev-lh-adp-dpa-adfir-neu";

    let createNatGateway = false;
    if (createNatGateway) {
      const pip = new PublicIp(this, `pip-nat-gateway-${commonConfig.workload}`, {
          ...commonConfig,
          name: naming.getName(PublicIp.tfResourceType, commonConfig, "cps-nat"),
          resourceGroupName: dlzCpsVnet.resourceGroupName,
          allocationMethod: "Static",
          sku: "Standard",
      })

      const nat = new NatGateway(this, `nat-gateway-${commonConfig.workload}`, {
          ...commonConfig,
          name: naming.getName(NatGateway.tfResourceType, commonConfig, "cps"),
          resourceGroupName: dlzCpsVnet.resourceGroupName,
          skuName: "Standard",
      })

      new NatGatewayPublicIpAssociation(this, `nat-ip-association-${commonConfig.workload}`, {
          natGatewayId: nat.id,
          publicIpAddressId: pip.id
      })

      new TerraformOutput(this, `nat-gateway-ip`, {
          value: pip.ipAddress
      })
    }

    let kvSecretArray = new Array();
    const secrets = [
      "self-hosted-integration-runtime-vm-username",
      "self-hosted-integration-runtime-vm-password",
      "self-hosted-integration-runtime-primary-authorization-key"]
    secrets.forEach(i => {
      let dlzDpaKvSecret = new DataAzurermKeyVaultSecret(this, `dlzDpaKvSecret-${i}`, {
        name: i,
        keyVaultId: "/subscriptions/bf34a2a9-7f5f-4d14-b6e9-ebb98711dd78/resourceGroups/rg-mblb-dev-lh-adp-dpa-neu/providers/Microsoft.KeyVault/vaults/kvmblbdevlhadpdpaneu"
      });
      kvSecretArray.push(dlzDpaKvSecret.value);
    });

    new AdpShirAdf(this, {
      ...commonConfig,
      component: "dps",
      resourceGroupName: dlzDpsResourceGroup.name,
      subnetId: `${dlzCpsVnet.id}/subnets/${dlzCpsShirSubnetName}`,
      adfKeys: {
        vmAdminUserName: kvSecretArray[0],
        vmAdminPassword: kvSecretArray[1],
        shirAuthKey: kvSecretArray[2]
      },
      directType: {
        vmSize: "Standard_B2ms",
        osdiskType: "Standard_LRS",
        sourceImageSku: "2022-Datacenter"
      }
    }, naming)
  };
}

const app = new App();
new ADPStack(app, "adp");
app.synth();