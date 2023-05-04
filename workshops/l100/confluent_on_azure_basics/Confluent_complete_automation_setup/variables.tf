#Kindly use the confluent api key. This will be available inside your confluent account
variable "confluent_cloud_api_key" {
  default = "6VYW62XVQZZAAN"
}
#Kindly use the confluent api scerets. This will be available inside your confluent account
variable "confluent_cloud_api_secret" {
 default = "4u3F6li9tvPC2bMeEGaKHGFxwM6KmJmvuKZJZWESR9qMi/Zl9ygEeCyNqWC79e"
}
#
variable "confluent_service_account-1" {
  default = "app-manager-2023-rr"
}

variable "confluent_service_account-2" {
  default = "app-consumer-2023-rr"
}

variable "confluent_service_account-3" {
  default = "app-producer-2023-rr"
}
variable "confluent_service_account-4" {
  default = "app-ksql-2023-rr"
}
#kindly provide resource group name of your choice as per naming convention"
variable "resource_group_name" {
  default = "confluent100"
}
#kindly provide cosmosdb name of your choice as per naming convention 
variable "azurerm_cosmosdb_account_name" {
  default = "confluent100"
}
// kafka cluster and azure resources both to be placed in the same cloud and region to restrict the fault isolation boundary.
#kindly provide the azure region. Recommended eastus2
variable "failover_location" {
  default = "eastus2"
}
variable "resource_group_location" {
  default = "eastus2"
}