# see https://github.com/hashicorp/terraform
terraform {
  required_version = ">= 0.13"
  required_providers {
    cloudinit = "~> 2.2.0"
    random    = "~> 3.1.0"
    azurerm   = "~> 2.95.0"
    azuread   = "~> 2.17.0"
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
    time = "~>0.7.2"
  }
}

# see https://github.com/terraform-providers/terraform-provider-azurerm
provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
  client_id                  = var.azure_client_id
  client_secret              = var.azure_client_secret
  skip_provider_registration = true
}

provider "azuread" {
  tenant_id     = var.tenant_id
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "time" {

}