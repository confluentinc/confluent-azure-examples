terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.39.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

resource "confluent_environment" "tf-cc-azure" {
  display_name = var.confluent_cloud_environment_display_name
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
data "confluent_schema_registry_region" "essentials" {
  cloud   = var.confluent_cloud_csp
  region  = var.confluent_cloud_csp_region
  package = var.confluent_cloud_stream_governance_package
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.essentials.package

  environment {
    id = confluent_environment.tf-cc-azure.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.essentials.id
  }
}
# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "azure-cluster-1" {
  display_name = var.confluent_cloud_cluster_display_name
  availability = var.confluent_cloud_cluster_availability
  cloud        = var.confluent_cloud_csp
  region       = var.confluent_cloud_csp_region
  basic {}
  environment {
    id = confluent_environment.tf-cc-azure.id
  }
}