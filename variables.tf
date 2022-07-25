# ---------------------------
# Azure Key Vault
# ---------------------------
variable "environment" {
}

variable "tenant_id" {
}
variable "subscription_id" {
}
variable "azure_client_id" {
}
variable "azure_client_secret" {
}

variable "location" {
  description = "Azure location where the Key Vault resource to be created"
  default     = "eastus"
}

// variable "application_name" {
//   type    = string
//   default = "SOCM"
// }

variable "seal_key_name" {
  description = "Azure Key Vault seal key name"
  default     = "socm-seal-key"
}

variable "root_key_name" {
  description = "Azure Key Vault root key name"
  default     = "socm-root-key"
}

variable "recovery_key_name" {
  description = "Azure Key Vault recovery key name"
  default     = "socm-recovery-key"
}

variable "authorized_app" {
  type        = string
  description = "Authorized Application ID"
}

variable "sap_endpoint" {
  type        = string
  description = "SAP Endpoint"
}

variable "ingress_key" {
  type        = string
  description = "Ingress SSL Key"
}

variable "ingress_crt" {
  type        = string
  description = "Ingress Certificate"
}

variable "socm_app_secret_rotation" {
  type        = number
  description = "Auto Rotate App Secret every (x) days"
  default     = 30
}

variable "rotate_socmsealkey" {
  type        = number
  description = "Auto Rotate SOCM Vault Seal Key every (x) days"
  default     = 30
}

variable "azure_vault" {
  type        = string
  description = "Azure Vault Name to be used"
}

variable "azure_vault_rg" {
  type        = string
  description = "Azure Vault Resource Group"
}

variable "socm_odata_replicas" {
  type        = number
  description = "Number of oData Replicas"
}

variable "ingress_ssl_port" {
  type        = number
  description = "Ingress SSL Port"
  default     = 443
}

variable "logger_port" {
  type        = number
  description = "FluentD Port"
  default     = 24224
}
variable "syslogger_port" {
  type        = number
  description = "FluentD SysLog Port"
  default     = 9898
}

variable "syslogger2_port" {
  type        = number
  description = "FluentD SysLog Port 2"
  default     = 9797
}

variable "log_level" {
  type        = string
  description = "Log Level"
  default     = "INFO"
}

variable "csrf_uri" {
  type        = string
  description = "URI to fetch X-CSRF-TOKEN"
  default     = "sap/opu/odata/sap/ZPRODORDCONF_SRV/$metadata"
}

variable "socm_application_id" {
  type        = string
  description = "SOCM Application ID"
}

variable "socm_scope" {
  type        = string
  description = "SOCM Scope"
  default     = "rw_sap_data"
}

variable "socm_user_key" {
  type        = string
  description = "SOCM User Key in JWT"
  default     = "preferred_username"
}

variable "fluentui_port" {
  type        = number
  description = "SOCM logger port"
  default     = 9292
}

variable "cert_tpl" {
  type        = string
  description = "Certificate Generation TPL"
  default     = "./src/odata-proxy/certmap.json.tpl"
}


