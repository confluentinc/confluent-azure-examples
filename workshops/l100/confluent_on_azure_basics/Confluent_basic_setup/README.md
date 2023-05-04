This terraform code will set up basic Confluent setup. This code will create Confluent Environment and Cluster.

The components created using this Terraform code are

- Environment 
- Cluster

### Prerequisites.

- Confluent Subscriptions 
- Git Bash - https://git-scm.com/downloads
- Terraform CLI - https://developer.hashicorp.com/terraform/downloads
- Confluent CLI - https://docs.confluent.io/confluent-cli/current/install.html

### Variable.tf 

In Variable.tf file we are passing the variables as parameters in the terraform script
Kindly update the appropriate values in the mentioned places.

`variable "confluent_cloud_api_key" {
  default = `"Kindly use the confluent api key. This will be available inside your confluent account."`
}`

`variable "confluent_cloud_api_secret" {
 default = `"Kindly use the confluent api scerets. This will be available inside your confluent account."`
}`
