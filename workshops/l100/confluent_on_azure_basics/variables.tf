variable "confluent_cloud_api_key" {
  default = "SOSIZU5CQLUHO5D7"
}

variable "confluent_cloud_api_secret" {
 default = "3VwhBBLfUytASmPEO4tl/GEznuRtOK+JW3vxPEg5U1YWdpsPIB9Eefq8djypXnn4"
}

variable "confluent_service_account-1" {
  default = "app-manager-2023-Test"
}

variable "confluent_service_account-2" {
  default = "app-consumer-2023-Test"
}

variable "confluent_service_account-3" {
  default = "app-producer-2023-Test"
}
variable "confluent_service_account-4" {
  default = "app-ksql-2023-Test"
}
variable "resource_group_name" {
  default = "confluentl100"
}
# kindly provide the region as westus2 as we have created confluent resources using the same region

variable "resource_group_location" {
  default = "westus2"
}
variable "azurerm_cosmosdb_account_name" {
  default = "confluentl100"
}
# kindly provide the region as westus2 as we have created confluent resources using the same region
variable "failover_location" {
  default = "westus2"
}
