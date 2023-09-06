provider "aws" {
  region = "us-east-1"  # Use the desired region
  access_key = "AKIAR4T234HWNW7ITZ7L"
  secret_key = "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"
}

# Step 1: Create S3 Bucket with ACL Disabled
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-devops-internship-bucket-karthikeyan"
}
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-logs-bucket-karthikeyan"
}



resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"
}
#upload
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "index.html"
  source = "./index.html"  # Replace with the actual path to your index.html file
  content_type = "text/html"
}
resource "aws_s3_object" "error_html" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "error.html"
  source = "./error.html"  # Replace with the actual path to your index.html file
  content_type = "text/html"
}

# Step 2: Create CloudFront Distribution
resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "My Origin Access Identity"
}

resource "aws_cloudfront_distribution" "my_distribution" {
  enabled             = true
  comment             = "My CloudFront Distribution"

  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "my-s3-origin"
  s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_oai.cloudfront_access_identity_path
    }
  }
custom_error_response {
    error_code      = 403  # The HTTP error code you want to handle
    response_code   = 200  # The HTTP response code to return
    response_page_path = "/error.html"  # The path to the custom error page in your S3 bucket
  }

  custom_error_response {
    error_code      = 404
    response_code   = 200
    response_page_path = "/error.html"
  }
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "my-s3-origin"

    viewer_protocol_policy = "redirect-to-https"

forwarded_values {
    query_string = false
    cookies {
      forward = "none"
    }
  }
}
  default_root_object = "index.html"
  aliases = ["karthikeyan1.mounickraj.com"]

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:130180440556:certificate/c3e205a0-0ffd-43e6-a421-6fe1db5c9b1f"  # Replace with your ACM certificate ARN
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
# Step 3: Set S3 Bucket Policy to Allow CloudFront Origin Access

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.my_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.my_oai.iam_arn]
    }
  }
}
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
#IAM policy role s3-cloud front
resource "aws_iam_role" "cloudfront_s3_role" {
  name = "CloudFrontS3Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      }
    ]
  })
}
#s3 policy for role
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Policy for accessing S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}
#attach both
resource "aws_iam_policy_attachment" "s3_access_attachment" {
   name="IAMPolicyAttachmentCloudFrontS3"
  policy_arn = aws_iam_policy.s3_access_policy.arn
  roles      = [aws_iam_role.cloudfront_s3_role.name]
}
#iam for ec2
resource "aws_iam_role" "ec2_full_access_role" {
  name = "EC2FullAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ec2_full_access_attachment" {
  name="IAMPolicyAttachmentEC2"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"  # Attach the built-in policy for full EC2 access
  roles      = [aws_iam_role.ec2_full_access_role.name]
}
