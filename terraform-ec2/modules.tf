# modules.tf - Stateful blog services: Cognito, S3 assets, CloudFront
#
# Migrated from the retired terraform-lightsail root on 29.08.2026 via a
# state move (no AWS resources were touched). These three carry STATE or
# identity (admin users, uploaded assets, the distribution + certificate)
# and are therefore excluded from the tear-down-and-rebuild cycle that
# applies to the compute layer in main.tf/eip.tf.
#
# Values are kept identical to the old root on purpose -- the migration
# is only proven when both roots plan "No changes".

locals {
  blog_domain = "techblog.aws.his4irness23.de"
}

# Admin authentication. Permanent -- admin users persist across rebuilds.
module "cognito" {
  source = "./modules/cognito"

  project_name     = "blog"
  domain_name      = "blog.aws.his4irness23.de" # legacy EKS callback URL, kept to avoid pool changes
  lightsail_domain = local.blog_domain
}

# Asset storage (images, Polly audio), served through CloudFront via OAC.
module "s3" {
  source = "./modules/s3"

  project_name     = "blog"
  lightsail_domain = local.blog_domain
}

# CDN: HTTPS termination, caching, /api/* pass-through to the EC2 origin.
module "cloudfront" {
  source = "./modules/cloudfront"

  project_name                   = "blog"
  s3_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  s3_bucket_arn                  = module.s3.bucket_arn
  s3_bucket_id                   = module.s3.bucket_id
  domain_name                    = local.blog_domain
  route53_zone_id                = data.aws_route53_zone.main.zone_id
  lightsail_origin_domain        = "origin-ec2.aws.his4irness23.de"
  origin_verify_secret           = var.origin_verify_secret

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}
