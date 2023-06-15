# Confluent on Azure Basics - Level 100

This workshop will provide you with the foundational knowledge of how to work with Confluent Cloud running on Microsoft Azure.

## Repository Information

This terraform code will set up basic Confluent setup. This code will create Confluent Environment and Cluster.

The components created using this Terraform code are

- Environment
- Cluster

### Prerequisites

- Confluent Cloud Subscription
- Terraform CLI - <https://developer.hashicorp.com/terraform/downloads>
- Confluent CLI - <https://docs.confluent.io/confluent-cli/current/install.html>

[//]: # (TODO Rewrite the Variables section to explain the workshop.tfvars file.)

### Variables

The `workshop.tfvars` file is used to declare variables to be passed as parameters into the main configuration of your module. Update the values in the `workshop.tfvars` file. You can search for the string `xx-replace-xx` to locate all instances of a variable that need your input.

``` zsh
confluent_cloud_csp = "xx-replace-xx"
confluent_cloud_csp_region = "xx-replace-xx"
```
