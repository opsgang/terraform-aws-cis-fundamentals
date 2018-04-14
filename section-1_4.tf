# AccessKey age check and delete function
## IAM Policy
data "template_file" "access_key_age_check_policy" {
  template = "${file("${path.module}/templates/lambda_access_key_age_check_policy.json.tpl")}"
}

resource "aws_iam_role" "access_key_age_check" {
  name               = "${var.resource_name_prefix}-access-key-age-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "access_key_age_check" {
  name   = "${var.resource_name_prefix}-lambda-access-key-age-check"
  role   = "${aws_iam_role.access_key_age_check.id}"
  policy = "${data.template_file.access_key_age_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "access_key_age_check" {
  type        = "zip"
  source_file = "${path.module}/files/access_key_age_check.py"
  output_path = "${var.temp_artifacts_dir}/access_key_age_check.zip"
}

resource "aws_lambda_function" "access_key_age_check" {
  filename         = "${var.temp_artifacts_dir}/access_key_age_check.zip"
  function_name    = "${var.resource_name_prefix}-access-key-age-check"
  role             = "${aws_iam_role.access_key_age_check.arn}"
  handler          = "access_key_age_check.lambda_handler"
  source_code_hash = "${data.archive_file.access_key_age_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = {
      DRY_RUN                = "${var.lambda_dry_run}"
      AGGRESSIVE             = "${var.lambda_aggressive}"
      KEY_AGE_MAX            = "${var.lambda_access_key_age_max}"
      KEY_AGE_NOTIFY         = "${var.lambda_access_key_age_notify}"
      IGNORE_IAM_USER_PREFIX = "${var.lambda_mfa_checker_user_prefix}"
      IGNORE_IAM_USER_SUFFIX = "${var.lambda_mfa_checker_user_suffix}"
    }
  }

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "access_key_age_check" {
  name                = "${var.resource_name_prefix}-access-key-age-check"
  description         = "remove expiring access keys"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "access_key_age_check" {
  rule      = "${aws_cloudwatch_event_rule.access_key_age_check.name}"
  target_id = "${var.resource_name_prefix}-access-key-age-check"
  arn       = "${aws_lambda_function.access_key_age_check.arn}"
}

resource "aws_lambda_permission" "access_key_age_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.access_key_age_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.access_key_age_check.arn}"
}

## /Schedule the lambda function
# /AccessKey age check and delete function

