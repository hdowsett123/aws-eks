#Backend
terraform {
  backend "s3" {
    bucket         = "terraform-state-kubernetes-app-2.0"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_state_locking"
    encrypt        = true
  }
}

#VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "kubernetes-vpc"
  cidr = "10.11.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.11.1.0/24", "10.11.2.0/24"]
  public_subnets  = ["10.11.3.0/24", "10.11.4.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

}

#EKS
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = "kubernetes-app-eks"
  cluster_version = "1.22"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 50
  }

  eks_managed_node_groups = {
    general = {
      desired_size = 1
      min_size     = 1
      max_size     = 10

      labels = {
        role = "general"
      }

      instance_types = ["t2.micro"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = {
    Environment = "staging"
  }
}


