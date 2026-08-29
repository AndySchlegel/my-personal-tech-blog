# iam-legacy.tf - TRANSITIONAL: IAM user the blog backend still uses
#
# Moved here from the terraform-lightsail root (state move, 29.08.2026) so
# destroying that root cannot delete the credentials the EC2 blog runs on:
# the access key of this user is the AWS_ACCESS_KEY_ID in /opt/blog/.env.
#
# SCHEDULED FOR REMOVAL: once the instance role (iam.tf) carries these
# permissions and the backend uses it via IMDSv2, delete this whole file
# and apply -- user, key and .env entries disappear together.

resource "aws_iam_user" "lightsail_backend" {
  #checkov:skip=CKV_AWS_273:Transitional -- replaced by the instance role, see file header
  name = "blog-lightsail-backend"

  tags = {
    Name = "blog-lightsail-backend"
  }
}

resource "aws_iam_user_policy" "lightsail_backend" {
  #checkov:skip=CKV_AWS_40:Inline policy is intentional for single-purpose transitional user
  #checkov:skip=CKV_AWS_355:Comprehend/Translate/Polly APIs don't support resource-level ARNs
  name = "blog-lightsail-backend-policy"
  user = aws_iam_user.lightsail_backend.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ComprehendAccess"
        Effect = "Allow"
        Action = [
          "comprehend:DetectKeyPhrases",
          "comprehend:DetectSentiment"
        ]
        Resource = "*"
      },
      {
        Sid    = "TranslateAccess"
        Effect = "Allow"
        Action = [
          "translate:TranslateText"
        ]
        Resource = "*"
      },
      {
        Sid    = "PollyAccess"
        Effect = "Allow"
        Action = [
          "polly:SynthesizeSpeech"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::blog-assets-his4irness23/*"
      }
    ]
  })
}

resource "aws_iam_access_key" "lightsail_backend" {
  user = aws_iam_user.lightsail_backend.name
}
