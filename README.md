# terraform-aws-cis-fundamentals

This Terraform module helps to setup an AWS account with the requirements of  CIS Amazon Web Services Foundations Benchmark v1.1.0

1. Identity and Access Management
    1. Avoid the use of the "root" account (Scored) - Cannot be codified
    2. Ensure multi-factor authentication (MFA) is enabled for all IAM users that have a console password (Scored)
    3. Ensure credentials unused for 90 days or greater are disabled (Scored)
    4. Ensure access keys are rotated every 90 days or less (Scored)
    5. Ensure IAM password policy requires at least one uppercase letter (Scored)
    6. Ensure IAM password policy require at least one lowercase letter (Scored)
    7. Ensure IAM password policy require at least one symbol (Scored)
    8. Ensure IAM password policy require at least one number (Scored)
    9. Ensure IAM password policy requires minimum length of 14 or greater (Scored)
    10. Ensure IAM password policy prevents password reuse (Scored)
    11. Ensure IAM password policy expires passwords within 90 days or less (Scored)
