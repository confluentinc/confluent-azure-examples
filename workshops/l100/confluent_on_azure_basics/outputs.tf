output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.tf-cc-azure.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.azure-cluster-1.id}
  EOT
  
  sensitive = true
}