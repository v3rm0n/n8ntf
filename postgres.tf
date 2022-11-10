locals {
    labels = {
        app = "postgres"
    }
    config_map_ref_name = "postgres-config"
}

resource "random_password" "postgres" {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_config_map" "postgres" {
    metadata {
        name      = local.config_map_ref_name
        namespace = kubernetes_namespace.n8n.metadata.0.name
        labels    = local.labels
    }

    data = {
        POSTGRES_DB       = "n8n"
        POSTGRES_USER     = "n8n"
        POSTGRES_PASSWORD = random_password.postgres.result
    }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
    metadata {
        name      = "postgres-pv-claim"
        namespace = kubernetes_namespace.n8n.metadata.0.name
        labels    = local.labels
    }
    spec {
        storage_class_name = "microk8s-hostpath"
        access_modes       = ["ReadWriteMany"]
        resources {
            requests = {
                storage = "5Gi"
            }
        }
    }
}

resource "kubernetes_deployment" "postgres" {
    metadata {
        name = "postgres"
        namespace = kubernetes_namespace.n8n.metadata.0.name
    }
    spec {
        replicas = "1"
        selector {
            match_labels = local.labels
        }
        template {
            metadata {
                labels = local.labels
            }
            spec {
                volume {
                    name = "postgredb"
                    persistent_volume_claim {
                        claim_name = kubernetes_persistent_volume_claim.postgres.metadata.0.name
                    }
                }
                container {
                    name              = "postgres"
                    image             = "postgres:15.0"
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
                            name = local.config_map_ref_name
                        }
                    }
                }
            }
        }
    }
}