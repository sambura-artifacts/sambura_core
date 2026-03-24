# --- NETWORK (VPC) ---
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# --- STORAGE (S3 Buckets) ---
module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

# --- DATABASE (RDS PostgreSQL) ---
module "database" {
  source           = "./modules/database"
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  db_subnet_group  = module.vpc.db_subnet_group
  db_password      = var.db_password
  app_sg_id        = module.eks.nodes_sg_id # SG dos nodes do EKS
}

# --- COMPUTE (EKS Cluster) ---
module "eks" {
  source           = "./modules/eks"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
}
