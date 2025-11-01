terraform {
  required_version = ">= 1.5"
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "< 1.0.0"
    }
  }
}

# variables
variable "model" {
  description = "tracing setup juju model. Defaults to `cos`."
  type        = string
  default     = "cos"
}

# tempo cluster
resource "juju_application" "tempo_coordinator" {
  name  = "tempo"
  model = var.model
  trust = true
  units = 1

  charm {
    name    = "tempo-coordinator-k8s"
    channel = "2/edge"
  }
}

resource "juju_application" "tempo_worker" {
  name  = "tempo-worker"
  model = var.model
  trust = true
  units = 1

  charm {
    name    = "tempo-worker-k8s"
    channel = "2/edge"
  }
}

resource "juju_application" "tempo_s3" {
  name  = "tempo-s3"
  model = var.model
  trust = true
  units = 1

  charm {
    name    = "seaweedfs-k8s"
    channel = "latest/edge"
  }
}

resource "juju_integration" "coordinator_to_s3" {
  model = var.model

  application {
    name     = juju_application.tempo_s3.name
    endpoint = "s3-credentials"
  }

  application {
    name     = juju_application.tempo_coordinator.name
    endpoint = "s3"
  }
}

resource "juju_integration" "coordinator_to_worker" {
  model = var.model

  application {
    name     = juju_application.tempo_coordinator.name
    endpoint = "tempo-cluster"
  }

  application {
    name     = juju_application.tempo_worker.name
    endpoint = "tempo-cluster"
  }
}

# grafana
resource "juju_application" "grafana" {
  name  = "grafana"
  model = var.model
  trust = true
  units = 1

  charm {
    name    = "grafana-k8s"
    channel = "2/edge"
  }
}

# traefik
resource "juju_application" "traefik" {
  name  = "traefik"
  model = var.model
  trust = true
  units = 1

  charm {
    name    = "traefik-k8s"
    channel = "latest/edge"
  }
}

# ingress relations (to accomodate for machine charms)
resource "juju_integration" "tempo_ingress" {

  model = var.model

  application {
    name     = juju_application.tempo_coordinator.name
    endpoint = "ingress"
  }

  application {
    name     = juju_application.traefik.name
    endpoint = "traefik-route"
  }
}

resource "juju_integration" "grafana_ingress" {

  model = var.model

  application {
    name     = juju_application.grafana.name
    endpoint = "ingress"
  }

  application {
    name     = juju_application.traefik.name
    endpoint = "traefik-route"
  }
}

# grafana source relations
resource "juju_integration" "grafana_source" {

  model = var.model

  application {
    name     = juju_application.tempo_coordinator.name
    endpoint = "grafana-source"
  }

  application {
    name     = juju_application.grafana.name
    endpoint = "grafana-source"
  }
}
