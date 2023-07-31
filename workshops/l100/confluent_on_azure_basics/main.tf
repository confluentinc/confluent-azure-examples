resource "confluent_invitation" "workshop_user" {
  email = var.user_email
  auth_type = "AUTH_TYPE_LOCAL"
}

resource "confluent_environment" "workshop-env" {
  display_name = "wkshp-${confluent_invitation.workshop_user.user[0].id}"
  depends_on = [ confluent_invitation.workshop_user ]
}

resource "confluent_role_binding" "role_bind_env_admin" {
  principal	= "User:${confluent_invitation.workshop_user.user[0].id}"
  role_name	= "EnvironmentAdmin"
  crn_pattern	= confluent_environment.workshop-env.resource_name
  depends_on = [confluent_environment.workshop-env]
}

data "confluent_schema_registry_region" "schema-registry-env" {
  cloud   = var.confluent_cloud_csp
  region  = var.confluent_cloud_csp_region
  package = var.confluent_cloud_stream_governance_package
}

resource "confluent_schema_registry_cluster" "schema-registry" {
  package = data.confluent_schema_registry_region.schema-registry-env.package

  environment {
    id = confluent_environment.workshop-env.id
  }

  region {
    id = data.confluent_schema_registry_region.schema-registry-env.id
  }
}
 
resource "confluent_kafka_cluster" "kafka-cluster" {
  display_name = "cluster-${confluent_invitation.workshop_user.user[0].id}"
  availability = var.confluent_cloud_cluster_availability
  cloud        = var.confluent_cloud_csp
  region       = var.confluent_cloud_csp_region
  basic {}
  environment {
    id = confluent_environment.workshop-env.id
  }
}