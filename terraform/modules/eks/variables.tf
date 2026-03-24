variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium" # EKS requer nodes com pelo menos 2vCPUs/4GB RAM
}
