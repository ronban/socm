resource "docker_service" "socm_ingress" {
  name = "${var.environment}-socm-ingress"

  endpoint_spec {
    mode = "vip"
    ports {
      name           = "nginx"
      protocol       = "tcp"
      target_port    = "443"
      published_port = var.ingress_ssl_port
      publish_mode   = "ingress"
    }
  }

  task_spec {
    container_spec {
      image = "nginx:1.21-alpine"

      secrets {
        secret_id   = docker_secret.ingress_key.id
        secret_name = docker_secret.ingress_key.name
        file_name   = "/run/secrets/ingress.key"
      }
      secrets {
        secret_id   = docker_secret.ingress_crt.id
        secret_name = docker_secret.ingress_crt.name
        file_name   = "/run/secrets/ingress.crt"
      }
      configs {
        config_id   = docker_config.ngnix_json_log.id
        config_name = docker_config.ngnix_json_log.name
        file_name   = "/etc/nginx/conf.d/json_log.conf"
      }
      configs {
        config_id   = docker_config.socm_ingress_conf.id
        config_name = docker_config.socm_ingress_conf.name
        file_name   = "/etc/nginx/nginx.conf"
      }
    }
    networks = [
      docker_network.socm_network.id
    ]

    placement {
      max_replicas = 1
    }
  }

  depends_on = [docker_service.socm_odata_proxy, docker_service.socm_vault]
}