data "azurerm_client_config" "current" {
}

# SOCM AD Application

resource "time_rotating" "rotate_socmappsecret" {
  rotation_days = var.socm_app_secret_rotation
}

resource "time_rotating" "rotate_socmsealkey" {
  rotation_days = var.rotate_socmsealkey
}

data "azuread_application" "socmapp" {
  application_id = var.socm_application_id
}

resource "azuread_application_pre_authorized" "mendixapp" {
  application_object_id = data.azuread_application.socmapp.object_id
  authorized_app_id     = var.authorized_app
  permission_ids        = [data.azuread_application.socmapp.oauth2_permission_scope_ids[var.socm_scope]]
}

resource "azuread_application_password" "socmclientpwd" {
  application_object_id = data.azuread_application.socmapp.object_id
  display_name          = "${var.environment}-socm-client-secret"
  end_date_relative     = "4320h"
  rotate_when_changed = {
    rotation = time_rotating.rotate_socmappsecret.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Key Vault

data "azurerm_key_vault" "vault" {
  name                = var.azure_vault
  resource_group_name = var.azure_vault_rg
}

# hashicorp vault will use this azurerm_key_vault_key to wrap/encrypt its master key.
resource "azurerm_key_vault_key" "seal_key" {
  name         = "${var.environment}-${var.seal_key_name}"
  key_vault_id = data.azurerm_key_vault.vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "wrapKey",
    "unwrapKey",
  ]
}

# hashicorp vault will use this azurerm_key to store the root key
resource "azurerm_key_vault_secret" "root_key" {
  name         = "${var.environment}-${var.root_key_name}"
  value        = "to be filled in by docker container"
  key_vault_id = data.azurerm_key_vault.vault.id
}

# hashicorp vault will use this azurerm_key to store recovery keys
resource "azurerm_key_vault_secret" "recovery_key" {
  name         = "${var.environment}-${var.recovery_key_name}"
  value        = "to be filled in by docker container"
  key_vault_id = data.azurerm_key_vault.vault.id
}

output "scope" {
  description = "SOCM Scope"
  value       = "${data.azuread_application.socmapp.identifier_uris[0]}/${var.socm_scope}"
}