// Admin configuration -- injected at deploy time
//
// In production (EKS): this file is replaced by a ConfigMap volume mount
// containing real Cognito values from Terraform outputs.
// In dev mode (local): this file ships with empty values, which triggers
// auth bypass in auth.js (isDevMode() returns true).
//
// DO NOT hardcode real values here -- they come from the deploy pipeline.
window.BLOG_CONFIG = {
  cognitoUserPoolId: "",
  cognitoClientId: "",
  cognitoDomain: "",
};
