## TODO - Test the experience with this vars file populated.

confluent_cloud_api_key = "xx-replace-xx"
confluent_cloud_api_secret = "xx-replace-xx"

# Enter your email address to receive an invitation to become an evnrionment administrator.
user_email = "xx-replace-xx"

# Update the following variables to use the cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
confluent_cloud_csp = "xx-replace-xx"
confluent_cloud_csp_region = "xx-replace-xx"
confluent_cloud_cluster_availability = "xx-replace-xx"

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
# Choosing your Stream Governance package version will also influence your region decision as ESSENTIALS
# and ADVANCED are not all hosted in the same regions.
# See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
confluent_cloud_stream_governance_package = "xx-replace-xx"