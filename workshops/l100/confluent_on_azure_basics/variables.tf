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

variable "user_email" {
  description = "Specifies the email address to use for the invitation to become an Environment Administrator"
  type = string
  sensitive = false
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

variable "confluent_cloud_cluster_availability" {
  description = "Choose your availability model for your cluster (SINGLE_ZONE or MULTI_ZONE)"
  default = "SINGLE_ZONE"
}

variable "confluent_cloud_stream_governance_package" {
  description = "Choose your Stream Governance package level here (ESSENTIALS or ADVANCED)"
  type = string
  default = "ESSENTIALS"
}
