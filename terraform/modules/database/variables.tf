variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "db_subnet_group" {
  description = "Nome do Subnet Group do DB"
  type        = string
}

variable "db_password" {
  description = "Senha master do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "app_sg_id" {
  description = "ID do Security Group da aplicação (para permitir acesso ao DB)"
  type        = string
}

variable "db_instance_class" {
  description = "Classe da instância do RDS"
  type        = string
  default     = "db.t4g.micro" # Free Tier eligible (ou baixo custo)
}

variable "db_allocated_storage" {
  description = "Espaço em GB"
  type        = number
  default     = 20
}
