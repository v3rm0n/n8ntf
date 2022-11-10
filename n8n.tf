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

resource "kubernetes_config_map" "n8n" {
    metadata {
        name      = "n8n"
        namespace = local.namespace
        labels    = local.app_labels
    }

    data = {
        DB_TYPE                = "postgresdb"
        DB_POSTGRESDB_DATABASE = "n8n"
        DB_POSTGRESDB_HOST     = "postgres"
        DB_POSTGRESDB_PORT     = "5432"
        DB_POSTGRESDB_USER     = "n8n"
        DB_POSTGRESDB_SCHEMA   = "public"
        DB_POSTGRESDB_PASSWORD = random_password.postgres.result
    }

}

resource "kubernetes_persistent_volume_claim" "n8n" {
    metadata {
        name      = "n8n-pv-claim"
        namespace = local.namespace
        labels    = local.app_labels
    }
    spec {
        access_modes = ["ReadWriteOnce"]
        resources {
            requests = {
                storage = "1Gi"
            }
        }
    }
}

resource "kubernetes_deployment" "n8n" {
    metadata {
        name      = "n8n"
        labels    = local.app_labels
        namespace = local.namespace
    }
    spec {
        replicas = "2"
        selector {
            match_labels = local.app_labels
        }
        template {
            metadata {
                name      = "n8n"
                labels    = local.app_labels
                namespace = local.namespace
            }
            spec {
                container {
                    name  = "n8n"
                    image = "n8nio/n8n"
                    args  = ["n8n", "start"]
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
                }
                volume {
                    name = "data"
                    persistent_volume_claim {
                        claim_name = kubernetes_persistent_volume_claim.n8n.metadata.0.name
                    }
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
            port        = 8080
        }
    }

    depends_on = [kubernetes_deployment.n8n]
}
