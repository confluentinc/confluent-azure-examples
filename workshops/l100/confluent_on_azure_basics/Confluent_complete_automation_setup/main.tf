#defind provider for Confluent and Azure
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.39.0"
    }
    azurerm = {
        source = "hashicorp/azurerm"
        version = "3.52.0"
    }
  }
}
#initialize confluent api and secrets
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}
provider "azurerm" {
     skip_provider_registration = "true"
  features {

  }
}
#creating azure resource group
resource "azurerm_resource_group" "rg" {
  name = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}
#creating azure cosmosdb
resource "azurerm_cosmosdb_account" "acc" {
 name = "${var.azurerm_cosmosdb_account_name}" 
 location = "${azurerm_resource_group.rg.location}"
 resource_group_name = "${azurerm_resource_group.rg.name}"
 offer_type = "Standard"
 kind = "GlobalDocumentDB"

 consistency_policy {
   consistency_level = "Session"
 }
 geo_location {
   location = "${var.failover_location}"
   failover_priority = 0
 }
}
#creating azure cosmosdb database
resource "azurerm_cosmosdb_sql_database" "db" {
  name = "testdb"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
  account_name = "${azurerm_cosmosdb_account.acc.name}"
}
#creating azure cosmosdb container
resource "azurerm_cosmosdb_sql_container" "con" {
  name ="terraformtestcontainer"
  resource_group_name = "${azurerm_cosmosdb_account.acc.resource_group_name}"
account_name = "${azurerm_cosmosdb_account.acc.name}"
database_name = "${azurerm_cosmosdb_sql_database.db.name}"
partition_key_path = "/terraformtestcontainerId"
}
#creating confluent enviroment
resource "confluent_environment" "staging" {
  display_name = "Confluent_L100"
}
#creating confluent cosmosdb sink connector
resource "confluent_connector" "cosmo-db-sink" {
  environment {
    id = confluent_environment.staging.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html#configuration-properties
  config_sensitive = {
    "connect.cosmos.master.key" = azurerm_cosmosdb_account.acc.primary_key
  }

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-mongo-db-sink.html#configuration-properties
  config_nonsensitive = {
    "connector.class"          = "CosmosDbSink"
    "name"                     = "CosmosDbSinkConnector_0"
    "input.data.format"        = "AVRO",
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connector.id
    "topics"                   = "Accomplished_female_reader",
    "connect.cosmos.connection.endpoint" = azurerm_cosmosdb_account.acc.endpoint,
    "connect.cosmos.databasename" = azurerm_cosmosdb_sql_database.db.name,
    "connect.cosmos.containers.topicmap" = "pageviews#${azurerm_cosmosdb_sql_container.con.name}",
    "cosmos.id.strategy" = "FullKeyStrategy",
    "tasks.max" = "1"
  }

  depends_on = [
    azurerm_cosmosdb_account.acc,
  ]
}

# Stream Governance and Kafka clusters can be in different regions as well as different cloud providers,
# but you should to place both in the same cloud and region to restrict the fault isolation boundary.
# creating confluent enviroment
data "confluent_schema_registry_region" "essentials" {
  cloud   = "AZURE"
  region  = "westus2"
  package = "ESSENTIALS"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.essentials.package

  environment {
    id = confluent_environment.staging.id
  }

  region {
    # See https://docs.confluent.io/cloud/current/stream-governance/packages.html#stream-governance-regions
    id = data.confluent_schema_registry_region.essentials.id
  }
}

# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
# creating confluent cluster
resource "confluent_kafka_cluster" "standard" {
  display_name = "C1"
  availability = "SINGLE_ZONE"
  cloud        = "AZURE"
  region       = "eastus2"
  standard {}
  environment {
    id = confluent_environment.staging.id
  }
}

// 'app-manager' service account is required in this configuration to create 'users' topic and grant ACLs
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "${var.confluent_service_account-1}"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.standard.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.staging.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}
# creating topic
resource "confluent_kafka_topic" "users" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "users"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
resource "confluent_kafka_topic" "pageview" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "pageview"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
resource "confluent_service_account" "app-consumer" {
  display_name = "${var.confluent_service_account-2}"
  description  = "Service account to consume from 'users' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-consumer-kafka-api-key" {
  display_name = "app-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-consumer' service account"
  owner {
    id          = confluent_service_account.app-consumer.id
    api_version = confluent_service_account.app-consumer.api_version
    kind        = confluent_service_account.app-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.staging.id
    }
  }
}

resource "confluent_kafka_acl" "app-producer-write-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.users.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
resource "confluent_kafka_acl" "app-producer-write-on-topic-1" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.pageview.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}


resource "confluent_service_account" "app-producer" {
  display_name = "${var.confluent_service_account-3}"
  description  = "Service account to produce to 'users' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
  owner {
    id          = confluent_service_account.app-producer.id
    api_version = confluent_service_account.app-producer.api_version
    kind        = confluent_service_account.app-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.staging.id
    }
  }
}

// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
// confluent_kafka_acl.app-consumer-read-on-topic, confluent_kafka_acl.app-consumer-read-on-group.
// https://docs.confluent.io/platform/current/kafka/authorization.html#using-acls
resource "confluent_kafka_acl" "app-consumer-read-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.users.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
resource "confluent_kafka_acl" "app-consumer-read-on-topic-1" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.pageview.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-consumer-read-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "GROUP"
  // The existing values of resource_name, pattern_type attributes are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update the values of resource_name, pattern_type attributes to match your target consumer group ID.
  // https://docs.confluent.io/platform/current/kafka/authorization.html#prefixed-acls
  resource_name = "confluent_cli_consumer_"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_service_account" "app-connector" {
  display_name = "app-connector"
  description  = "Service account of S3 Sink Connector to consume from 'users' topic of 'inventory' Kafka cluster"
}


resource "confluent_kafka_acl" "app-connector-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-target-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.users.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
resource "confluent_kafka_acl" "app-connector-write-on-target-topic-1" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.pageview.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-write-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connector.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}
# creating datagen source connector
resource "confluent_connector" "source-1" {
  environment {
    id = confluent_environment.staging.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html#configuration-properties
  config_sensitive = {}

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html#configuration-properties
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "DatagenSourceConnector_users"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connector.id
    "kafka.topic"              = confluent_kafka_topic.users.topic_name
    "output.data.format"       = "JSON"
    "quickstart"               = "users"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-connector-describe-on-cluster,
    confluent_kafka_acl.app-connector-write-on-target-topic,
    confluent_kafka_acl.app-connector-create-on-data-preview-topics,
    confluent_kafka_acl.app-connector-write-on-data-preview-topics,
  ]
}

resource "confluent_connector" "source-2" {
  environment {
    id = confluent_environment.staging.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }

  // Block for custom *sensitive* configuration properties that are labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html#configuration-properties
  config_sensitive = {}

  // Block for custom *nonsensitive* configuration properties that are *not* labelled with "Type: password" under "Configuration Properties" section in the docs:
  // https://docs.confluent.io/cloud/current/connectors/cc-datagen-source.html#configuration-properties
  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "DatagenSourceConnector_pv"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connector.id
    "kafka.topic"              = confluent_kafka_topic.pageview.topic_name
    "output.data.format"       = "JSON"
    "quickstart"               = "pageviews"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-connector-describe-on-cluster,
    confluent_kafka_acl.app-connector-write-on-target-topic,
    confluent_kafka_acl.app-connector-create-on-data-preview-topics,
    confluent_kafka_acl.app-connector-write-on-data-preview-topics,
  ]
}
// creating ksqlDB service account with only the necessary access
resource "confluent_service_account" "app-ksql" {
  display_name = "${var.confluent_service_account-4}"
  description  = "Service account for Ksql cluster"
}

resource "confluent_ksql_cluster" "main" {
  display_name = "ksqlDB"
  csu = 1
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  credential_identity {
    id = confluent_service_account.app-ksql.id
  }
  environment {
    id = confluent_environment.staging.id
  }

  depends_on = [
    confluent_schema_registry_cluster.essentials,
    confluent_role_binding.app-ksql-schema-registry-resource-owner
  ]
}

resource "confluent_kafka_acl" "app-ksql-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-describe-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-describe-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-describe-configs-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE_CONFIGS"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-describe-configs-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE_CONFIGS"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-describe-configs-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE_CONFIGS"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-describe-on-transactional-id" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TRANSACTIONAL_ID"
  resource_name = confluent_ksql_cluster.main.topic_prefix
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-write-on-transactional-id" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TRANSACTIONAL_ID"
  resource_name = confluent_ksql_cluster.main.topic_prefix
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-all-on-topic-prefix" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_ksql_cluster.main.topic_prefix
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-all-on-topic-confluent" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = "_confluent-ksql-${confluent_ksql_cluster.main.topic_prefix}"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-ksql-all-on-group-confluent" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "GROUP"
  resource_name = "_confluent-ksql-${confluent_ksql_cluster.main.topic_prefix}"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

# Topic specific permissions. You have to add an ACL like this for every Kafka topic you work with.
resource "confluent_kafka_acl" "app-ksql-all-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.users.topic_name
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-ksql.id}"
  host          = "*"
  operation     = "ALL"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_role_binding" "app-ksql-schema-registry-resource-owner" {
  principal   = "User:${confluent_service_account.app-ksql.id}"
  role_name   = "ResourceOwner"
  crn_pattern = format("%s/%s", confluent_schema_registry_cluster.essentials.resource_name, "subject=*")
}

# ACLs are needed for KSQL service account to read/write data from/to kafka, this role instead is needed for giving
# access to the Ksql cluster.
resource "confluent_role_binding" "app-ksql-ksql-admin" {
  principal   = "User:${confluent_service_account.app-ksql.id}"
  role_name   = "KsqlAdmin"
  crn_pattern = confluent_ksql_cluster.main.resource_name
}

resource "confluent_api_key" "app-ksqldb-api-key" {
  display_name = "app-ksqldb-api-key"
  description  = "KsqlDB API Key that is owned by 'app-ksql' service account"
  owner {
    id          = confluent_service_account.app-ksql.id
    api_version = confluent_service_account.app-ksql.api_version
    kind        = confluent_service_account.app-ksql.kind
  }

  managed_resource {
    id          = confluent_ksql_cluster.main.id
    api_version = confluent_ksql_cluster.main.api_version
    kind        = confluent_ksql_cluster.main.kind

    environment {
      id = confluent_environment.staging.id
    }
  }
}