resource "docker_service" "socm_logger" {
  name = "${var.environment}-socm-logger"

  endpoint_spec {
    mode = "vip"
    ports {
      name           = "logger"
      protocol       = "tcp"
      target_port    = "9292"
      published_port = var.fluentui_port
      publish_mode   = "ingress"
    }
  }

  task_spec {
    container_spec {
      image = "socm-logger:${var.environment}"
      env = {
        FLUENTD_CONF = "fluentd.conf",
        RAILS_RELATIVE_URL_ROOT="/logger"
      }

      mounts {
        target = "/fluentd/log"
        source = docker_volume.fluentd_logs.name
        type   = "volume"
      }

      configs {
        config_id   = docker_config.socm_logger_conf.id
        config_name = docker_config.socm_logger_conf.name
        file_name   = "/root/fluentd.conf"
      }
    }
    networks = [
      docker_network.socm_network.id
    ]

    placement {
      max_replicas = 1
    }
  }

}