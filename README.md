# terraform-aws-cis-fundamentals

This Terraform module helps to setup an AWS account with the requirements of  CIS Amazon Web Services Foundations Benchmark v1.1.0

1. Identity and Access Management
    1. Avoid the use of the "root" account (Scored) - Cannot be codified
    2. Ensure multi-factor authentication (MFA) is enabled for all IAM users that have a console password (Scored)
    3. Ensure credentials unused for 90 days or greater are disabled (Scored)
    4. Ensure access keys are rotated every 90 days or less (Scored)
