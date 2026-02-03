module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name                   = local.name
  cluster_endpoint_public_access = true

  ############################################
  # ✅ EKS ACCESS ENTRY (REPLACES aws-auth)
  ############################################
  access_entries = {
    tws_admin = {
      principal_arn = "arn:aws:iam::715841342014:user/tws-ecom"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  ############################################
  # EKS ADDONS
  ############################################
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
 vpc-cni = {
      most_recent = true
    }
  }

  ############################################
  # NETWORKING
  ############################################
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  ############################################
  # NODE GROUP DEFAULTS
  ############################################
  eks_managed_node_group_defaults = {
    instance_types = ["t2.large"]
    attach_cluster_primary_security_group = true
  }

  ############################################
  # MANAGED NODE GROUP
  ############################################
  eks_managed_node_groups = {
    tws-demo-ng = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t2.large"]
      capacity_type  = "SPOT"
   disk_size = 35
      use_custom_launch_template = false

      tags = {
        Name        = "tws-demo-ng"
        Environment = "dev"
        ExtraTag    = "e-commerce-app"
      }
    }
  }

  tags = local.tags
}

############################################
# OPTIONAL: FETCH EKS NODE EC2 INSTANCES
############################################
data "aws_instances" "eks_nodes" {
  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}


