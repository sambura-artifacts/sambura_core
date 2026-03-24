variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados."
  type        = "string"
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente (dev, prod, staging)."
  type        = "string"
  default     = "dev"
}

variable "project_name" {
  description = "Nome base para os recursos do projeto."
  type        = "string"
  default     = "sambura"
}

variable "vpc_cidr" {
  description = "Faixa de IP da rede (VPC)."
  type        = "string"
  default     = "10.0.0.0/16"
}

variable "db_password" {
  description = "Senha master do RDS PostgreSQL (Ideal passar via CLI ou var de ambiente)."
  type        = "string"
  sensitive   = true
}
