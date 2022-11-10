locals {
  cloudflared_labels = {
    app = "cloudflared"
  }
}

resource "kubernetes_secret" "cloudflared_token" {
  metadata {
    name      = "cloudflared-token"
    namespace = local.namespace
  }
  data = {
    "credentials.json" = file(var.cloudflare_tunnel_cred_file_name)
  }
}

resource "kubernetes_config_map" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = local.namespace
  }
  data = {
    "config.yaml" = <<EOF
tunnel: n8n
credentials-file: /etc/cloudflared/creds/credentials.json
metrics: 0.0.0.0:2000
ingress:
- hostname: ${var.domain_name}
  service: http://${kubernetes_service.n8n.metadata.0.name}:5678
- service: http_status:404
EOF
  }
}

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    labels    = local.cloudflared_labels
    namespace = local.namespace
  }
  spec {
    replicas = "2"
    selector {
      match_labels = local.cloudflared_labels
    }
    template {
      metadata {
        name      = "cloudflared"
        labels    = local.cloudflared_labels
        namespace = local.namespace
      }
      spec {
        container {
          name  = "cloudflared"
          image = "cloudflare/cloudflared:latest"
          args = [
            "tunnel", "--config",
            "/etc/cloudflared/config/config.yaml", "run"
          ]
          liveness_probe {
            http_get {
              path = "/ready"
              port = "2000"
            }
            failure_threshold     = 1
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          volume_mount {
            mount_path = "/etc/cloudflared/config"
            name       = "config"
            read_only  = true
          }
          volume_mount {
            mount_path = "/etc/cloudflared/creds"
            name       = "creds"
            read_only  = true
          }
        }
        volume {
          name = "creds"
          secret {
            secret_name = kubernetes_secret.cloudflared_token.metadata.0.name
          }
        }
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.cloudflared.metadata.0.name
            items {
              key  = "config.yaml"
              path = "config.yaml"
            }
          }

        }
      }
    }
  }
}
