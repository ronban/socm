resource "docker_service" "socm_vault" {
  name = "${var.environment}-socm-vault"

  update_config {
    parallelism       = 2
    delay             = "10s"
    failure_action    = "pause"
    monitor           = "5s"
    max_failure_ratio = "0.1"
    order             = "start-first"
  }

  rollback_config {
    parallelism       = 2
    delay             = "5ms"
    failure_action    = "pause"
    monitor           = "10h"
    max_failure_ratio = "0.9"
    order             = "stop-first"
  }

  depends_on = [
    azuread_application_password.socmclientpwd,
    azurerm_key_vault_key.seal_key,
    azurerm_key_vault_secret.root_key,
    azurerm_key_vault_secret.recovery_key
  ]

  task_spec {
    networks = [
      docker_network.socm_network.id
    ]
    placement {
      max_replicas = 1
    }

    container_spec {
      image = "socm-vault:${var.environment}"

      mounts {
        target = "/vault/file"
        source = docker_volume.vault_file.name
        type   = "volume"
      }

      mounts {
        target = "/vault/logs"
        source = docker_volume.vault_logs.name
        type   = "volume"
      }

      configs {
        config_id   = docker_config.azure_tenant_id.id
        config_name = docker_config.azure_tenant_id.name
        file_name   = "/run/config/azure_tenant_id"
      }

      configs {
        config_id   = docker_config.socm_app_id.id
        config_name = docker_config.socm_app_id.name
        file_name   = "/run/config/socm_app_id"
      }

      configs {
        config_id   = docker_config.socm_azkv_name.id
        config_name = docker_config.socm_azkv_name.name
        file_name   = "/run/config/socm_azkv_name"
      }

      configs {
        config_id   = docker_config.socm_azkv_sealkey.id
        config_name = docker_config.socm_azkv_sealkey.name
        file_name   = "/run/config/socm_azkv_sealkey"
      }

      configs {
        config_id   = docker_config.socm_azkv_rootkey.id
        config_name = docker_config.socm_azkv_rootkey.name
        file_name   = "/run/config/socm_azkv_rootkey"
      }

      configs {
        config_id   = docker_config.socm_azkv_reckey.id
        config_name = docker_config.socm_azkv_reckey.name
        file_name   = "/run/config/socm_azkv_reckey"
      }

      configs {
        config_id   = docker_config.socm_azkv_reckey.id
        config_name = docker_config.socm_azkv_reckey.name
        file_name   = "/run/config/socm_azkv_reckey"
      }

      configs {
        config_id   = docker_config.socm_logger_host.id
        config_name = docker_config.socm_logger_host.name
        file_name   = "/run/config/socm_logger_host"
      }

      configs {
        config_id   = docker_config.socm_logger_port.id
        config_name = docker_config.socm_logger_port.name
        file_name   = "/run/config/socm_logger_port"
      }

      configs {
        config_id   = docker_config.socm_syslogger2_port.id
        config_name = docker_config.socm_syslogger2_port.name
        file_name   = "/run/config/socm_syslogger2_port"
      }
      configs {
        config_id   = docker_config.socm_user_key.id
        config_name = docker_config.socm_user_key.name
        file_name   = "/run/config/socm_user_key"
      }

      secrets {
        secret_id   = docker_secret.socm_app_secret.id
        secret_name = docker_secret.socm_app_secret.name
        file_name   = "/run/secrets/socm_app_secret"
      }

      healthcheck {
        test         = ["CMD", "curl", "-f", "http://localhost:8200/v1/sys/health"]
        interval     = "5s"
        timeout      = "2s"
        retries      = 4
        start_period = "20s"
      }

      env = {
        VAULT_RECOVERY_SHARES    = "5"
        VAULT_RECOVERY_THRESHOLD = "2"
        VAULT_ROOTCA_CN          = "Ryerson ${var.environment} SAP OIDC Root CA"
        VAULT_SUBCA_CN           = "Ryerson ${var.environment} SAP OIDC Sub CA"
        VAULT_OU                 = "SAP Fiori ${var.environment}"
        VAULT_ORG_NAME           = "Ryerson ${var.environment}"
        VAULT_CLIENT_CERT_TTL    = "2m"
        VAULT_API_ADDR           = "http://${var.environment}-socm-vault:8200"
      }

    }
  }
}