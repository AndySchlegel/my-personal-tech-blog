# variables.tf - Cognito module input variables

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "domain_name" {
  description = "Blog domain for callback URLs (e.g. blog.aws.his4irness23.de)"
  type        = string
  # Used to construct OAuth callback URLs where Cognito redirects after login.
}

variable "lightsail_domain" {
  description = "Lightsail blog domain for callback URLs (e.g. techblog.aws.his4irness23.de)"
  type        = string
  default     = ""
  # Added as additional callback/logout URL alongside the EKS domain.
}
