# Resource: Security Group para o Banco de Dados (RDS)
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security Group para o RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # Ingress: Permitir apenas conexões da aplicação (Porta 5432)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  # Egress: Sem restrições de saída
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# Resource: RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db-${var.environment}"
  engine               = "postgres"
  engine_version       = "16" # Alinhado com o docker-compose
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp3"
  
  db_name              = "sambura_metadata"
  username             = "sambura"
  password             = var.db_password
  
  db_subnet_group_name = var.db_subnet_group
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  # Boas práticas para MVP
  skip_final_snapshot  = true
  publicly_accessible  = false
  multi_az             = false # Economiza custos no MVP
  
  # Performance Insights (opcional)
  performance_insights_enabled = true
  
  tags = {
    Name = "${var.project_name}-db"
  }
}
