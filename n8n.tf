locals {
  app_labels = {
    app = "n8n"
  }
  namespace = kubernetes_namespace.n8n.metadata.0.name
}

resource "kubernetes_namespace" "n8n" {
  metadata {
    name = "n8n"
  }
}

resource "random_password" "n8n_encryption_key" {
  length = 20
}

resource "kubernetes_secret" "n8n" {
  metadata {
    name      = "n8n-secret"
    namespace = local.namespace
    labels    = local.app_labels
  }
  data = {
    N8N_ENCRYPTION_KEY = random_password.n8n_encryption_key.result
  }
}

resource "kubernetes_config_map" "n8n" {
  metadata {
    name      = "n8n"
    namespace = local.namespace
    labels    = local.app_labels
  }

  data = {
    DB_TYPE                = "postgresdb"
    DB_POSTGRESDB_DATABASE = local.postgres_db
    DB_POSTGRESDB_HOST     = kubernetes_service.postgres.metadata.0.name
    DB_POSTGRESDB_PORT     = "5432"
    DB_POSTGRESDB_USER     = local.postgres_user
    DB_POSTGRESDB_SCHEMA   = "public"
    N8N_PORT               = "5678"
  }
}

resource "kubernetes_deployment" "n8n" {
  metadata {
    name      = "n8n"
    labels    = local.app_labels
    namespace = local.namespace
  }
  spec {
    replicas = "1"
    selector {
      match_labels = local.app_labels
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        name   = "n8n"
        labels = local.app_labels
      }
      spec {
        container {
          name  = "n8n"
          image = "n8nio/n8n"
          args  = ["/bin/sh", "-c", "sleep 5; n8n start"]
          port {
            container_port = 5678
          }
          volume_mount {
            mount_path = "/home/node/.n8n"
            name       = "data"
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.n8n.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.n8n.metadata.0.name
            }
          }
          env {
            name = "DB_POSTGRESDB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata.0.name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
        }
        volume {
          name = "data"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "n8n" {
  metadata {
    name      = "n8n"
    labels    = local.app_labels
    namespace = local.namespace
  }
  spec {
    selector = local.app_labels
    port {
      protocol    = "TCP"
      target_port = "5678"
      port        = 5678
    }
  }
  depends_on = [kubernetes_deployment.n8n]
}
