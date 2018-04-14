# MFA check and disable function
## IAM Policy
data "template_file" "mfa_check_policy" {
  template = "${file("${path.module}/templates/lambda_mfa_check_policy.json.tpl")}"
}

resource "aws_iam_role" "mfa_check" {
  name               = "${var.resource_name_prefix}-mfa-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "mfa_check" {
  name   = "${var.resource_name_prefix}-lambda-mfa-check"
  role   = "${aws_iam_role.mfa_check.id}"
  policy = "${data.template_file.mfa_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "mfa_check" {
  type        = "zip"
  source_file = "${path.module}/files/mfa_check.py"
  output_path = "${var.temp_artifacts_dir}/mfa_check.zip"
}

resource "aws_lambda_function" "mfa_check" {
  filename         = "${var.temp_artifacts_dir}/mfa_check.zip"
  function_name    = "${var.resource_name_prefix}-mfa-check"
  role             = "${aws_iam_role.mfa_check.arn}"
  handler          = "mfa_check.lambda_handler"
  source_code_hash = "${data.archive_file.mfa_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = {
      DRY_RUN                = "${var.lambda_dry_run}"
      AGGRESSIVE             = "${var.lambda_aggressive}"
      IGNORE_IAM_USER_PREFIX = "${var.lambda_mfa_checker_user_prefix}"
      IGNORE_IAM_USER_SUFFIX = "${var.lambda_mfa_checker_user_suffix}"
    }
  }

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "mfa_check" {
  name                = "${var.resource_name_prefix}-mfa-check"
  description         = "disables users without MFA"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "mfa_check" {
  rule      = "${aws_cloudwatch_event_rule.mfa_check.name}"
  target_id = "${var.resource_name_prefix}-mfa-check"
  arn       = "${aws_lambda_function.mfa_check.arn}"
}

resource "aws_lambda_permission" "mfa_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.mfa_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.mfa_check.arn}"
}

## /Schedule the lambda function
# /MFA check and disable function

