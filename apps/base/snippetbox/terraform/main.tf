terraform {
  required_providers {
    azurerm = {
      version = ">= 3.84"
    }

    random = {
      version = ">= 3.6"
    }

    kubernetes = {
      version = ">= 2.24"
    }

    atlas = {
      source  = "ariga/atlas"
      version = ">= 0.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "atlas" {
  dev_url = "mysql://root:pass@mysql.default.svc.cluster.local:3306"
}

data "azurerm_client_config" "current" {}

# Configure the Terraform remote state backend.
data "terraform_remote_state" "environment" {
  backend = "azurerm"

  config = {
    storage_account_name = var.storage_account
    resource_group_name  = var.resource_group
    container_name       = "tfstate"
    key                  = "${var.environment}.${var.location}.tfstate"
  }
}

data "atlas_schema" "default" {
  src = file("templates/schema.hcl")
}

locals {
  # Lookup and set the location abbreviation, defaults to na (not available).
  location_abbreviation = try(var.location_abbreviation[var.location], "na")

  # Lookup and set the environment abbreviation, defaults to na (not available).
  environment_abbreviation = try(var.environment_abbreviation[var.environment], "na")

  # Construct the name suffix.
  suffix = "${var.app}-${local.environment_abbreviation}-${local.location_abbreviation}"
}

# Generate a random suffix for the Azure MySQL Flexible Server.
resource "random_id" "mysql" {
  byte_length = 3
}

resource "random_password" "mysqladmin" {
  length = 16
}

resource "azurerm_key_vault_secret" "mysqladmin" {
  name         = "${var.app}-mysqladmin"
  value        = random_password.mysqladmin.result
  key_vault_id = data.terraform_remote_state.environment.outputs.azurerm_key_vault_default_id
}

# Create the resource group.
resource "azurerm_resource_group" "default" {
  name     = "rg-${local.suffix}"
  location = var.location
}

resource "azurerm_mysql_flexible_server" "default" {
  name                   = "mysql-${var.app}-${local.environment_abbreviation}-${random_id.mysql.hex}"
  resource_group_name    = azurerm_resource_group.default.name
  location               = var.location
  administrator_login    = "mysqladmin"
  administrator_password = random_password.mysqladmin.result
  sku_name               = "B_Standard_B1s"
  zone                   = "1"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_all" {
  name                = "AllowAll"
  resource_group_name = azurerm_resource_group.default.name
  server_name         = azurerm_mysql_flexible_server.default.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "atlas_schema" "default" {
  url = "mysql://mysqladmin:${urlencode(random_password.mysqladmin.result)}@${azurerm_mysql_flexible_server.default.fqdn}:3306?tls=preferred"
  hcl = data.atlas_schema.default.hcl

  depends_on = [azurerm_mysql_flexible_server_firewall_rule.allow_all]
}

# Create the Kubernetes namespace.
resource "kubernetes_namespace_v1" "default" {
  metadata {
    name = var.app

    labels = {
      app = var.app
    }
  }
}

# Create the mysql-atlas Kubernetes deployment.
resource "kubernetes_deployment_v1" "mysql_atlas" {
  metadata {
    name      = "mysql-atlas"
    namespace = kubernetes_namespace_v1.default.metadata[0].name

    labels = {
      app       = var.app
      component = "schema"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = var.app
        component = "schema"
      }
    }

    template {
      metadata {
        labels = {
          app       = var.app
          component = "schema"
        }
      }

      spec {
        container {
          image = "mysql:8"
          name  = "mysql-atlas"

          port {
            container_port = 3306
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            tcp_socket {
              port = "3306"
            }

            initial_delay_seconds = 15
          }
        }
      }
    }
  }
}

# Create the mysql-atlas Kubernetes service.
resource "kubernetes_service_v1" "mysql_atlas" {
  metadata {
    name      = "mysql-atlas"
    namespace = kubernetes_namespace_v1.default.metadata[0].name

    labels = {
      app       = var.app
      component = "schema"
    }
  }

  spec {
    selector = {
      app       = var.app
      component = "schema"
    }

    port {
      port        = 80
      target_port = 4000
    }
  }
}

# Create the snipperbox Kubernetes deployment.
resource "kubernetes_deployment_v1" "snipperbox" {
  metadata {
    name      = var.app
    namespace = kubernetes_namespace_v1.default.metadata[0].name

    labels = {
      app       = var.app
      component = "web"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = var.app
        component = "web"
      }
    }

    template {
      metadata {
        labels = {
          app       = var.app
          component = "web"
        }
      }

      spec {
        container {
          image = var.container_image
          name  = var.app

          port {
            container_port = 4000
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 4000
            }

            initial_delay_seconds = 10
          }
        }
      }
    }
  }
}

# Create the snipperbox Kubernetes service.
resource "kubernetes_service_v1" "snipperbox" {
  metadata {
    name      = var.app
    namespace = kubernetes_namespace_v1.default.metadata[0].name

    labels = {
      app       = var.app
      component = "web"
    }
  }

  spec {
    selector = {
      app       = var.app
      component = "web"
    }

    port {
      port        = 80
      target_port = 4000
    }
  }
}

# Create the ingress.
resource "kubernetes_ingress_v1" "default" {
  metadata {
    name      = var.app
    namespace = kubernetes_namespace_v1.default.metadata[0].name

    labels = {
      app = var.app
    }

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    tls {
      hosts       = [var.ingress_rule_host]
      secret_name = var.app
    }

    rule {
      host = var.ingress_rule_host

      http {
        path {
          backend {
            service {
              name = var.app
              port {
                number = 80
              }
            }
          }

          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}
