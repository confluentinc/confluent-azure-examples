[//]: # (TODO - Rewrite this for the L100 Azure workshop.)

# Build a Streaming Data Pipeline on Confluent Cloud with GCS

This Qwiklab will introduce you to Confluent Cloud and help you build a streaming data pipeline to send data to Google Cloud Storage.

## Repository Information

This terraform code will set up a Confluent Cloud environment and invite a user with access to the newly created environment.

The components created using this Terraform code are:

- [Confluent Cloud Environment](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_environment)
- [Confluent Cloud Invitation](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_invitation)
- [Confluent Cloud Role Binding](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_role_binding)

### Prerequisites

- [Confluent Cloud Subscription](https://confluent.cloud)
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads)

### Variables

The `qwiklab.tfvars` file is used to declare variables to be passed as input parameters to the Terraform code and modules. You can search for the string `xx-replace-xx` to locate all instances of a variable that need your input to run this lab.

``` zsh
confluent_cloud_csp = "xx-replace-xx"
confluent_cloud_csp_region = "xx-replace-xx"
user_email = "xx-replace-xx"
```
