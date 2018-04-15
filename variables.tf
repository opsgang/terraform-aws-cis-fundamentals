variable "resource_name_prefix" {
  description = "All the resources will be prefixed with this varible"
  default     = "aws-cis"
}

variable "tags" {
  description = "Hash of tags will be used in all resources"
  default     = {}
}

variable "lambda_timeout" {
  description = "Default timeout of lambda fucntions"
  default     = 180
}

variable "lambda_dry_run" {
  description = "Sets DRY_RUN environment variable for all lambda functions"
  default     = false
}

variable "lambda_aggressive" {
  description = "Sets AGGRESSIVE mode as true for lambda fucntions"
  default     = true
}

variable "lambda_mfa_checker_user_prefix" {
  description = "Comma separated list of prefixes that mfa checker lambda helper will ignore"
  default     = ""
}

variable "lambda_mfa_checker_user_suffix" {
  description = "Comma separated list of suffixes that mfa checker lambda helper will ignore"
  default     = ""
}

variable "lambda_user_inactivity_limit" {
  description = "Disable inactive users more than N days"
  default     = 90
}

variable "lambda_access_key_age_max" {
  description = "Expire access keys after N days"
  default     = 90
}

variable "lambda_access_key_age_notify" {
  description = "Start to send notifications for expiring keys N before"
  default     = 7
}

variable "lambda_cron_schedule" {
  description = "Default Cron schedule for lambda helpers"
  default     = "cron(0 6 * * ? *)"
}

variable "temp_artifacts_dir" {
  description = "The path for creating the zip file"
  default     = "/tmp/terraform-aws-cis-fundatentals/artifacts"
}

variable "iam_require_uppercase_characters" {
  description = "Require at least one uppercase letter in passwords"
  default     = true
}

variable "iam_require_lowercase_characters" {
  description = "Require at least one lowercase letter in passwords"
  default     = true
}

variable "iam_require_symbols" {
  description = "Require at least one symbol in passwords"
  default     = true
}

variable "iam_require_numbers" {
  description = "Require at least one number in passwords"
  default     = true
}

variable "iam_minimum_password_length" {
  description = "Require minimum lenght of password"
  default     = 14
}

variable "iam_password_reuse_prevention" {
  description = "Prevent password reuse N times"
  default     = 24
}

variable "iam_max_password_age" {
  description = "Passwords expire in N days"
  default     = 90
}

variable "iam_allow_users_to_change_password" {
  description = "Can users change their own password"
  default     = true
}

variable "iam_hard_expiry" {
  description = "Everyone needs hard reset for expired passwords"
  default     = true
}
