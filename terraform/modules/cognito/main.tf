# main.tf - Cognito User Pool for admin authentication
#
# AWS Cognito is a managed authentication service. Instead of building
# our own login system (password hashing, session management, MFA, etc.),
# Cognito handles all of that for us.
#
# How it works:
#   1. Admin navigates to /admin/login
#   2. Frontend redirects to Cognito's hosted login page
#   3. Admin enters email + password (+ optional MFA)
#   4. Cognito redirects back to /admin/callback with an authorization code
#   5. Frontend exchanges the code for JWT tokens (access + id + refresh)
#   6. Frontend sends the access token with every API request
#   7. Backend validates the JWT token against this Cognito pool
#
# Only admin users (1-2 people) will use this pool.
# Regular blog visitors never interact with Cognito.

# --- User Pool ---
# The user pool is the "user database" -- it stores admin accounts,
# handles authentication, and issues JWT tokens.
resource "aws_cognito_user_pool" "admin" {
  name = "${var.project_name}-admin-pool"

  # Strong password policy for admin accounts.
  # 12 chars minimum with all character types required.
  # Since only 1-2 admins use this, a strict policy is appropriate.
  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7 # Temporary password expires after 7 days
  }

  # Users sign in with their email address (not a username).
  # Cognito treats the email as the unique identifier.
  username_attributes = ["email"]

  # When a user signs up, automatically send a verification email.
  # They must click the link before they can log in.
  auto_verified_attributes = ["email"]

  # Use Cognito's built-in email service (free tier: 50 emails/day).
  # For 1-2 admins this is more than enough. If you needed more,
  # you'd switch to SES (Simple Email Service) for higher limits.
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # If an admin forgets their password, they can reset it via email.
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # MFA (Multi-Factor Authentication) is OPTIONAL.
  # Admins can enable TOTP (Time-based One-Time Password) via an
  # authenticator app (Google Authenticator, Authy, etc.).
  # We avoid SMS-based MFA because AWS charges per SMS message.
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-admin-pool"
  }
}

# --- App Client ---
# The app client is how our frontend application talks to Cognito.
# Think of it as an "API key" that identifies our blog's admin dashboard.
#
# Important: generate_secret = false because this is a browser-based SPA.
# A browser cannot securely store a client secret (anyone can view the source).
# Server-side apps (like a Node.js backend) could use a secret, but SPAs cannot.
resource "aws_cognito_user_pool_client" "admin" {
  name         = "${var.project_name}-admin-client"
  user_pool_id = aws_cognito_user_pool.admin.id

  generate_secret = false # SPA cannot securely store secrets

  # Allowed authentication flows:
  # ALLOW_USER_SRP_AUTH:       Secure Remote Password protocol -- password never leaves
  #                            the browser in plain text. This is the recommended flow.
  # ALLOW_REFRESH_TOKEN_AUTH:  Allows using refresh tokens to get new access tokens
  #                            without re-entering credentials (30-day sessions).
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Where Cognito redirects after successful login.
  # The frontend catches the authorization code at /admin/callback
  # and exchanges it for JWT tokens.
  callback_urls = [
    "https://${var.domain_name}/admin/callback", # Production
    "http://localhost:8080/admin/callback"       # Local development
  ]

  # Where Cognito redirects after logout.
  logout_urls = [
    "https://${var.domain_name}/admin",
    "http://localhost:8080/admin"
  ]

  # OAuth 2.0 configuration:
  # "code" flow = Authorization Code Grant (most secure for SPAs).
  # The browser gets a short-lived code, then exchanges it for tokens.
  # Alternative "implicit" flow sends tokens directly in the URL (less secure).
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"] # Only Cognito accounts, no Google/Facebook

  # Token lifetimes:
  # Access token (1 hour): sent with every API request, short-lived for security
  # ID token (1 hour): contains user profile info (email, name, groups)
  # Refresh token (30 days): used to silently get new access tokens without re-login
  access_token_validity  = 1  # 1 hour
  id_token_validity      = 1  # 1 hour
  refresh_token_validity = 30 # 30 days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

# --- Cognito Domain ---
# This creates a hosted login page at:
#   https://blog-admin-auth.auth.eu-central-1.amazoncognito.com
# It's a ready-to-use login UI provided by Cognito.
# Later we could customize this or build our own login page.
resource "aws_cognito_user_pool_domain" "admin" {
  domain       = "${var.project_name}-admin-auth"
  user_pool_id = aws_cognito_user_pool.admin.id
}

# --- Admin Group ---
# User groups allow role-based access control (RBAC).
# The backend checks if the JWT token contains "admin-group" in the
# "cognito:groups" claim. Only users in this group can access
# the admin dashboard (create/edit posts, moderate comments, upload images).
#
# To add an admin user:
#   aws cognito-idp admin-add-user-to-group \
#     --user-pool-id <pool-id> \
#     --username <email> \
#     --group-name admin-group
resource "aws_cognito_user_group" "admin" {
  name         = "admin-group"
  user_pool_id = aws_cognito_user_pool.admin.id
  description  = "Admin users with full dashboard access"
}
