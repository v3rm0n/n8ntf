locals {
  postgres_db   = "n8n"
  postgres_user = "n8n"
  postgres_labels = {
    app = "postgres"
  }
  postgres_namespace = kubernetes_namespace.n8n.metadata.0.name
}

resource "random_password" "postgres" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-password"
    namespace = local.namespace
    labels    = local.postgres_labels
  }

  data = {
    POSTGRES_PASSWORD = random_password.postgres.result
  }
}

resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres-config"
    namespace = local.postgres_namespace
    labels    = local.postgres_labels
  }

  data = {
    POSTGRES_DB   = local.postgres_db
    POSTGRES_USER = local.postgres_user
  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres-pv-claim"
    namespace = local.postgres_namespace
    labels    = local.postgres_labels
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = local.postgres_namespace
    labels    = local.postgres_labels
  }
  spec {
    replicas = "1"
    selector {
      match_labels = local.postgres_labels
    }
    template {
      metadata {
        labels = local.postgres_labels
      }
      spec {
        container {
          name              = "postgres"
          image             = "postgres:14.5"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 5432
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgredb"
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgres.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.postgres.metadata.0.name
            }
          }
        }
        volume {
          name = "postgredb"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    labels    = local.postgres_labels
    namespace = local.namespace
  }
  spec {
    selector = local.postgres_labels
    port {
      protocol    = "TCP"
      target_port = "5432"
      port        = 5432
    }
  }

  depends_on = [kubernetes_deployment.postgres]
}
