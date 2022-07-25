resource "docker_service" "socm_odata_proxy" {
  name = "${var.environment}-socm-odata-proxy"

  task_spec {
    container_spec {
      image = "socm-odata_proxy:${var.environment}"
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
        config_id   = docker_config.socm_user_key.id
        config_name = docker_config.socm_user_key.name
        file_name   = "/run/config/socm_user_key"
      }

      configs {
        config_id   = docker_config.socm_sap_endpoint.id
        config_name = docker_config.socm_sap_endpoint.name
        file_name   = "/run/config/sap_endpoint"
      }

      configs {
        config_id   = docker_config.socm_vault_uri.id
        config_name = docker_config.socm_vault_uri.name
        file_name   = "/run/config/socm_vault_uri"
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
        config_id   = docker_config.socm_logger_port.id
        config_name = docker_config.socm_logger_port.name
        file_name   = "/run/config/socm_logger_port"
      }

      configs {
        config_id   = docker_config.socm_log_level.id
        config_name = docker_config.socm_log_level.name
        file_name   = "/run/config/socm_log_level"
      }

      configs {
        config_id   = docker_config.socm_metadata_uri.id
        config_name = docker_config.socm_metadata_uri.name
        file_name   = "/run/config/socm_metadata_uri"
      }

      configs {
        config_id   = docker_config.socm_python_logger.id
        config_name = docker_config.socm_python_logger.name
        file_name   = "/app/flaskAppServer/logging.yaml"
      }

      configs {
        config_id   = docker_config.socm_cert_template.id
        config_name = docker_config.socm_cert_template.name
        file_name   = "/app/flaskAppServer/cert_template.json.tpl"
      }

      healthcheck {
        test     = ["CMD", "curl", "-f", "http://localhost:5001/health"]
        interval = "5s"
        timeout  = "2s"
        retries  = 4
      }
    }
    networks = [docker_network.socm_network.id]
  }

  mode {
    replicated {
      replicas = var.socm_odata_replicas
    }
  }

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

}