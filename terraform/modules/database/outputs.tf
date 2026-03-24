output "db_host" {
  description = "Endpoint de conexão do banco de dados"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Porta do banco de dados"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.main.db_name
}

output "db_sg_id" {
  description = "ID do Security Group do DB"
  value       = aws_security_group.db_sg.id
}
