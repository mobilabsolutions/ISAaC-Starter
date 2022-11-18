import { Construct } from "constructs";
import { App, AzurermBackend, TerraformStack } from "cdktf";
import { AzurermProvider } from "@cdktf/provider-azurerm/lib/provider";
import { HttpProvider } from "@cdktf/provider-http/lib/provider";
import { AzureadProvider } from "@cdktf/provider-azuread/lib/provider";
import { RandomProvider } from "@cdktf/provider-random/lib/provider";
import { load } from "js-yaml";
import { readFileSync } from "fs";
import {AdpCommonConfig, DefaultNaming} from "adp/adp/common";
import {AdpLakehouse} from "adp/adp/organisms/adp-lakehouse";

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

    //todo tag validation?
    const commonConfig = load(readFileSync(ADPStack.COMMON_CONFIG_FILE, ADPStack.UTF8_ENCODING)) as AdpCommonConfig;

    new AzurermBackend(this, {
        ...commonConfig.tfstate
    });

    const naming = new DefaultNaming();

    new AdpLakehouse(this, {
        ...commonConfig,
    },
    naming);

  };
}

const app = new App();
new ADPStack(app, "adp");
app.synth();
