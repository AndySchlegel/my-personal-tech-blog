# variables.tf - S3 module input variables (Lightsail-only version)
#
# Simplified from the EKS S3 module: removed domain_name (EKS) and
# environment variables. Only lightsail_domain is needed for CORS.

variable "project_name" {
  description = "Project name used in bucket naming"
  type        = string
}

variable "lightsail_domain" {
  description = "Lightsail blog domain for CORS (e.g. techblog.aws.his4irness23.de)"
  type        = string
  # CORS needs the exact domain that will make requests to S3.
  # The admin dashboard at this domain uploads images via pre-signed URLs.
}
