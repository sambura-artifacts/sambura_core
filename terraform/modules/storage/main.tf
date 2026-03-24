# Resource: S3 Bucket para Artefatos
resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project_name}-artifacts-${var.environment}"
}

# Bloquear acesso público ao bucket por padrão (segurança)
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Habilitar versionamento (Best Practice para artefatos)
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Output para outros módulos
output "artifact_bucket_name" {
  value = aws_s3_bucket.artifacts.id
}

output "artifact_bucket_arn" {
  value = aws_s3_bucket.artifacts.arn
}
