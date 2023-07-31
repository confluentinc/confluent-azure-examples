output "workshop_user" {
  value = confluent_invitation.workshop_user
}

output "Confluent-Environment-Info" {
  value = confluent_environment.workshop-env.display_name
}

output "Kafka-Cluster-Info" {
  value = confluent_kafka_cluster.kafka-cluster
}