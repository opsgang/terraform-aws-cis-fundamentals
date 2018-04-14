# Inactivity check and disable function
## IAM Policy
data "template_file" "inactivity_check_policy" {
  template = "${file("${path.module}/templates/lambda_inactivity_check_policy.json.tpl")}"
}

resource "aws_iam_role" "inactivity_check" {
  name               = "${var.resource_name_prefix}-inactivity-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "inactivity_check" {
  name   = "${var.resource_name_prefix}-lambda-inactivity-check"
  role   = "${aws_iam_role.inactivity_check.id}"
  policy = "${data.template_file.inactivity_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "inactivity_check" {
  type        = "zip"
  source_file = "${path.module}/files/inactivity_check.py"
  output_path = "${var.temp_artifacts_dir}/inactivity_check.zip"
}

resource "aws_lambda_function" "inactivity_check" {
  filename         = "${var.temp_artifacts_dir}/inactivity_check.zip"
  function_name    = "${var.resource_name_prefix}-inactivity-check"
  role             = "${aws_iam_role.inactivity_check.arn}"
  handler          = "inactivity_check.lambda_handler"
  source_code_hash = "${data.archive_file.inactivity_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = {
      DRY_RUN                = "${var.lambda_dry_run}"
      AGGRESSIVE             = "${var.lambda_aggressive}"
      INACTIVITY_LIMIT       = "${var.lambda_user_inactivity_limit}"
      IGNORE_IAM_USER_PREFIX = "${var.lambda_mfa_checker_user_prefix}"
      IGNORE_IAM_USER_SUFFIX = "${var.lambda_mfa_checker_user_suffix}"
    }
  }

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "inactivity_check" {
  name                = "${var.resource_name_prefix}-inactivity-check"
  description         = "disables inactive users"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "inactivity_check" {
  rule      = "${aws_cloudwatch_event_rule.inactivity_check.name}"
  target_id = "${var.resource_name_prefix}-inactivity-check"
  arn       = "${aws_lambda_function.inactivity_check.arn}"
}

resource "aws_lambda_permission" "inactivity_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.inactivity_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.inactivity_check.arn}"
}

## /Schedule the lambda function
# /MFA check and disable function

