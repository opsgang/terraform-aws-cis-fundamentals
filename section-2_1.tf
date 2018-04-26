data "aws_caller_identity" "current" {}

data "template_file" "cloudtrail_kms" {
  template = "${file("${path.module}/templates/cloudtrail_kms_policy.json.tpl")}"

  vars {
    aws_account_id = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_kms_key" "cloudtrail" {
  description             = "Encrypt/Decrypt cloudtrail logs"
  deletion_window_in_days = 30
  is_enabled              = true
  enable_key_rotation     = true

  #policy = "${var.cloudtrail_kms_policy != "" ? "${var.cloudtrail_kms_policy}" : "${data.template_file.cloudtrail_kms.rendered}"}"
  policy = "${data.template_file.cloudtrail_kms.rendered}"

  tags = "${var.tags}"
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.resource_name_prefix}-cloudtrail"
  target_key_id = "${aws_kms_key.cloudtrail.key_id}"
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = "${var.resource_name_prefix}-trail"
  s3_bucket_name                = "${var.cloudtrail_s3_bucket_name}"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = "${aws_kms_key.cloudtrail.arn}"

  event_selector {
    read_write_type           = "${var.clodtrail_event_selector_type}"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  tags = "${var.tags}"
}

# CloudTrail check
## IAM Policy
data "template_file" "cloudtrail_status_check_policy" {
  template = "${file("${path.module}/templates/lambda_cloudtrail_status_check_policy.json.tpl")}"
}

resource "aws_iam_role" "cloudtrail_status_check" {
  name               = "${var.resource_name_prefix}-cloudtrail-status-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "cloudtrail_status_check" {
  name   = "${var.resource_name_prefix}-lambda-cloudtrail-status-check"
  role   = "${aws_iam_role.cloudtrail_status_check.id}"
  policy = "${data.template_file.cloudtrail_status_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "cloudtrail_status_check" {
  type        = "zip"
  source_file = "${path.module}/files/cloudtrail_status_check.py"
  output_path = "${var.temp_artifacts_dir}/cloudtrail_status_check.zip"
}

resource "aws_lambda_function" "cloudtrail_status_check" {
  filename         = "${var.temp_artifacts_dir}/cloudtrail_status_check.zip"
  function_name    = "${var.resource_name_prefix}-cloudtrail-status-check"
  role             = "${aws_iam_role.cloudtrail_status_check.arn}"
  handler          = "cloudtrail_status_check.lambda_handler"
  source_code_hash = "${data.archive_file.cloudtrail_status_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "cloudtrail_status_check" {
  name                = "${var.resource_name_prefix}-cloudtrail-status-check"
  description         = "remove expiring access keys"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "cloudtrail_status_check" {
  rule      = "${aws_cloudwatch_event_rule.cloudtrail_status_check.name}"
  target_id = "${var.resource_name_prefix}-cloudtrail-status-check"
  arn       = "${aws_lambda_function.cloudtrail_status_check.arn}"
}

resource "aws_lambda_permission" "cloudtrail_status_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.cloudtrail_status_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.cloudtrail_status_check.arn}"
}

## /Schedule the lambda function
# /# CloudTrail check

