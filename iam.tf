#Policies and Roles
module "allow_eks_access_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name          = "allow-eks-access"
  create_policy = true

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "eks:DescribeCluster"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })
}

module "eks_admins_iam_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  create_role       = true
  role_name         = "eks-admin"
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]
  trusted_role_arns       = ["arn:aws:iam::${var.vpc_owner_id}:root"]
}

module "allow_assume_eks_admins_iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name          = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Effect" : "Allow",
        "Resource" : module.eks_admins_iam_role.iam_role_arn
      }
    ]
  })
}

module "eks_admins_iam_group" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name                              = "eks-admin"
  group_users                       = ["devops-admin"]
  attach_iam_self_management_policy = false
  create_group                      = true

  custom_group_policy_arns = [module.allow_assume_eks_admins_iam_policy.arn]
}


