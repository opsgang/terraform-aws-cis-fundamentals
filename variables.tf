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

variable "lambda_cron_schedule" {
  description = "Default Cron schedule for lambda helpers"
  default     = "cron(0 6 * * ? *)"
}

variable "temp_artifacts_dir" {
  description = "The path for creating the zip file"
  default     = "/tmp/terraform-aws-cis-fundatentals/artifacts"
}
