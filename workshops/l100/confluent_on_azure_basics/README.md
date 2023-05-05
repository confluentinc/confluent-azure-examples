# Confluent on Azure Basics - Level 100

This workshop will provide you with the foundational knowledge of how to work with Confluent Cloud running on Microsoft Azure.

## Repository Information

This terraform code will set up basic Confluent setup. This code will create Confluent Environment and Cluster.

The components created using this Terraform code are

- Environment
- Cluster

### Prerequisites

- Confluent Cloud Subscription
- Git Bash - https://git-scm.com/downloads
- Terraform CLI - https://developer.hashicorp.com/terraform/downloads
- Confluent CLI - https://docs.confluent.io/confluent-cli/current/install.html

### Variables

The `variables.tf` file is used to declare variables to be passed as parameters into the main configuration of your module. Update the values in the `variables.tf` file. You can search for the string `xx-replace-xx` to locate all instances of a variable that need your input.

`variable "confluent_cloud_api_key" {
  default = `"xx-replace-xx"`
}`

`variable "confluent_cloud_api_secret" {
 default = `"xx-replace-xx"`
}`