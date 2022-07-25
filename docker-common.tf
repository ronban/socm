resource "docker_volume" "vault_file" {
  name = "${var.environment}-socm_vault_file"
}

resource "docker_volume" "vault_logs" {
  name = "${var.environment}-socm_vault_logs"
}

resource "docker_volume" "fluentd_logs" {
  name = "${var.environment}-socm_fluentd_logs"
}

resource "docker_network" "socm_network" {
  name   = "${var.environment}-socm-overlay-network"
  driver = "overlay"
}


resource "docker_secret" "socm_app_secret" {
  name = "${var.environment}-socm-app-secret-${replace(timestamp(), ":", ".")}"
  data = base64encode(azuread_application_password.socmclientpwd.value)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_secret" "ingress_key" {
  name = "${var.environment}-ingress-key-${replace(timestamp(), ":", ".")}"
  data = base64encode(file(var.ingress_key))

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_secret" "ingress_crt" {
  name = "${var.environment}-ingress-crt-${replace(timestamp(), ":", ".")}"
  data = base64encode(file(var.ingress_crt))

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}


resource "docker_config" "socm_app_id" {
  name = "${var.environment}-socm-app-id-${replace(timestamp(), ":", ".")}"
  data = base64encode(data.azuread_application.socmapp.application_id)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_audience_uri" {
  name = "${var.environment}-socm_audience_uri-${replace(timestamp(), ":", ".")}"
  data = base64encode(data.azuread_application.socmapp.identifier_uris[0])

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_user_key" {
  name = "${var.environment}-socm_user_key-${replace(timestamp(), ":", ".")}"
  data = base64encode(var.socm_user_key)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_log_level" {
  name = "${var.environment}-socm-log-lvl-${replace(timestamp(), ":", ".")}"
  data = base64encode(var.log_level)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "azure_tenant_id" {
  name = "${var.environment}-azure-tenant-id-${replace(timestamp(), ":", ".")}"
  data = base64encode(data.azurerm_client_config.current.tenant_id)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_sap_endpoint" {
  name = "${var.environment}-socm-sap-endpoint-${replace(timestamp(), ":", ".")}"
  data = base64encode(var.sap_endpoint)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_vault_uri" {
  name = "${var.environment}-socm_vault_uri-${replace(timestamp(), ":", ".")}"
  data = base64encode("http://${var.environment}-socm-vault:8200")

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_azkv_name" {
  name = "${var.environment}-socm-azkv-name${replace(timestamp(), ":", ".")}"
  data = base64encode(data.azurerm_key_vault.vault.name)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_logger_host" {
  name = "${var.environment}-socm_logger_host${replace(timestamp(), ":", ".")}"
  data = base64encode("${var.environment}-socm-logger")

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_logger_port" {
  name = "${var.environment}-socm_logger_port${replace(timestamp(), ":", ".")}"
  data = base64encode("${var.logger_port}")

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_syslogger2_port" {
  name = "${var.environment}-socm_syslogger2_port-${replace(timestamp(), ":", ".")}"
  data = base64encode("${var.syslogger2_port}")

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_metadata_uri" {
  name = "${var.environment}-socm_metadata_uri${replace(timestamp(), ":", ".")}"
  data = base64encode("${var.csrf_uri}")

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_azkv_sealkey" {
  name = "${var.environment}-socm-azkv-sealkey-${replace(timestamp(), ":", ".")}"
  data = base64encode(azurerm_key_vault_key.seal_key.name)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_azkv_rootkey" {
  name = "${var.environment}-socm-azkv-rootkey-${replace(timestamp(), ":", ".")}"
  data = base64encode(azurerm_key_vault_secret.root_key.name)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_azkv_reckey" {
  name = "${var.environment}-socm-azkv-reckey-${replace(timestamp(), ":", ".")}"
  data = base64encode(azurerm_key_vault_secret.recovery_key.name)

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_ingress_conf" {
  name = "${var.environment}-socm_ingress_conf-${replace(timestamp(), ":", ".")}"
  data = base64encode(
    templatefile("${path.cwd}/src/ingress/nginx.conf.tpl",
      {
        odata_host = "${var.environment}-socm-odata-proxy",
        vault_host = "${var.environment}-socm-vault",
        logger_host = "${var.environment}-socm-logger",
        logger_port = "${var.syslogger_port}"
      }
    )
  )

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "ngnix_json_log" {
  name = "${var.environment}-ngnix_json_log-${replace(timestamp(), ":", ".")}"
  data = base64encode(
    templatefile("${path.cwd}/src/ingress/json_log.tpl",
      {
        logger_port = "${var.logger_port}"
      }
    )
  )

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_logger_conf" {
  name = "${var.environment}-socm_logger_conf-${replace(timestamp(), ":", ".")}"
  data = base64encode(
    templatefile("${path.cwd}/src/fluentd/fluentd.conf.tpl",
      {
        logger_port = "${var.logger_port}",
        syslogger_port = "${var.syslogger_port}",
        syslogger2_port = "${var.syslogger2_port}"
      }
    )
  )

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_python_logger" {
  name = "${var.environment}-socm_py_logger-${replace(timestamp(), ":", ".")}"
  data = base64encode(
    templatefile("${path.cwd}/src/odata-proxy/logging.yaml.tpl",
      {
        logger_port = "${var.logger_port}"
        logger_host = "${var.environment}-socm-logger"
        log_level = "${var.log_level}"
      }
    )
  )

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "docker_config" "socm_cert_template" {
  name = "${var.environment}-socm_cert_tpl-${replace(timestamp(), ":", ".")}"
  data = base64encode(file(var.cert_tpl))

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}
