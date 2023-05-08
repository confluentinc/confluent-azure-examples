variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_environment_display_name" {
  description = "(Required String) A human-readable name for the Environment. Start and end the name with alphanumeric characters, for example, (Development). The name can contain hyphens and underscores."
  type = string
  default = "Confluent_Azure_Workshop"
}

variable "confluent_cloud_csp" {
  description = "CSP for Confluent Cloud to built on"
  type = string
  default = "AZURE"
}

variable "confluent_cloud_csp_region" {
  description = "CSP Region to run Confluent Cloud in"
  type = string
}

variable "confluent_cloud_cluster_display_name" {
  description = "(Required String) The name of the Kafka cluster."
  type = string
}

variable "confluent_cloud_cluster_availability" {
  description = "Choose your availability model for your cluster (SINGLE_ZONE or MULTI_ZONE)"
}

variable "confluent_cloud_stream_governance_package" {
  description = "Choose your Stream Governance package level here (ESSENTIALS or ADVANCED)"
  type = string
  default = "ESSENTIALS"
}
