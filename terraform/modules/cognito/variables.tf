# variables.tf - Cognito module input variables

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "domain_name" {
  description = "Blog domain for callback URLs (e.g. blog.his4irness23.de)"
  type        = string
  # Used to construct OAuth callback URLs where Cognito redirects after login:
  # https://blog.his4irness23.de/admin/callback
}
