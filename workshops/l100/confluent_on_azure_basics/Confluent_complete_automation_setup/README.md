This terraform code is used to set up Resource group and Cosmos DB in Azure and Confluent the Environment, Cluster, Topic, Ksql and Connectors. This Terraform code will create all the required components for producing and consuming the message stream using confluent kafka.

The components created using this Terraform code are.

### Azure

- Resource group 
- Cosmos DB-nosql 

### Confluent

- Environments 
- Cluster 
- Topic
- Ksql
- Connectors - Datagen source and cosmos db sink.

### Prerequisites

- Azure Subscriptions 
- Confluent Subscriptions 
- Git Bash - https://git-scm.com/downloads
- Terraform CLI - https://developer.hashicorp.com/terraform/downloads
- Confluent CLI - https://docs.confluent.io/confluent-cli/current/install.html
- Azure CLI - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt

### Variable.tf

In Variable.tf file we are passing the variables as parameters in the terraform script
Kindly update the appropriate values in the mentioned places.

`variable "confluent_cloud_api_key" {
  default = "`Kindly use the confluent api key. This will be available inside your confluent account`"
}`

`variable "confluent_cloud_api_secret" {
 default = `"Kindly use the confluent api scerets. This will be available inside your confluent account"`
}`

`variable "confluent_service_account-1" {
  default = `"app-manager-confluent-your name"`
}`

`variable "confluent_service_account-2" {
  default = `"app-consumer-confluent-your name"`
}`

`variable "confluent_service_account-3" {
  default = `"app-producer-confluent-your name"`
}`

`variable "confluent_service_account-4" {
  default = `"app-ksql-confluent-your name”`
}`

`variable "resource_group_name" {
  default = `"kindly provide resource group name of your choice as per naming convention"`
}`

`variable "azurerm_cosmosdb_account_name" {
  default = `" kindly provide cosmosdb name of your choice as per naming convention "`
}`

`variable "failover_location" {
  default = `"kindly provide the azure region. Recommended eastus2"`
}`

`variable "resource_group_location" {
  default = `"kindly provide the azure region. Recommended eastus2"`
}`

##### Kindly provide the region as eastus2. It is advised to create confluent and azure resources using the same cloud and region to restrict the fault isolation boundary.
##### In the terraform code confluent cluster is created using eastus2
