# variables.tf - S3 module input variables

variable "project_name" {
  description = "Project name used in bucket naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "domain_name" {
  description = "Blog domain for CORS configuration (e.g. blog.his4irness23.de)"
  type        = string
  # CORS needs the exact domain that will make requests to S3.
  # The admin dashboard at this domain uploads images via pre-signed URLs.
}
