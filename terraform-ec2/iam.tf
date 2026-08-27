# iam.tf - IAM role and instance profile for the blog host
#
# The role is what replaces long-lived AWS access keys on the instance:
# any process on the host (via IMDSv2) can obtain short-lived credentials
# for exactly the permissions attached here -- nothing more.
#
# Starts EMPTY on purpose: permissions get added the moment the blog
# migration needs them (S3 backups, etc.), each as its own policy with
# a reason. An empty role costs nothing and already satisfies the
# baseline check that every instance should have one.

# Trust policy: only the EC2 service may assume this role, and only
# from within this account. This is NOT a permission -- it only says
# who is allowed to wear the role.
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "blog" {
  name               = "blog-ec2-role"
  description        = "Instance role for the blog EC2 host, permissions added per use case"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# The instance profile is the wrapper EC2 needs to hand a role to an
# instance -- a role alone cannot be attached directly.
resource "aws_iam_instance_profile" "blog" {
  name = "blog-ec2-profile"
  role = aws_iam_role.blog.name
}
