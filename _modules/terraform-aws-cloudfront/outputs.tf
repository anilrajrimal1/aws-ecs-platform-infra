output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

# output "origin_access_identity_path" {
#   description = "Path of the CloudFront origin access identity"
#   value       = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
# }

output "s3_bucket_id" {
  description = "ID of the S3 bucket used as origin"
  value       = data.aws_s3_bucket.origin_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket used as origin"
  value       = data.aws_s3_bucket.origin_bucket.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket used as origin"
  value       = data.aws_s3_bucket.origin_bucket.bucket_domain_name
}

output "cloudfront_create_acm_cert_arn" {
  description = "ARN of the ACM certificate created for CloudFront"
  value       = length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].arn : null
}

output "cloudfront_s3_oac_id" {
  description = "ID of the S3 Origin Access Control (OAC) created for CloudFront"
  value       = var.existing_s3_oac_id != null ? var.existing_s3_oac_id : aws_cloudfront_origin_access_control.s3_oac[0].id

}
