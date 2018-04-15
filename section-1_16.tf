# AccessKey age check and delete function
## IAM Policy
data "template_file" "user_policies_check_policy" {
  template = "${file("${path.module}/templates/lambda_user_policies_check_policy.json.tpl")}"
}

resource "aws_iam_role" "user_policies_check" {
  name               = "${var.resource_name_prefix}-user-policies-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "user_policies_check" {
  name   = "${var.resource_name_prefix}-lambda-user-policies-check"
  role   = "${aws_iam_role.user_policies_check.id}"
  policy = "${data.template_file.user_policies_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "user_policies_check" {
  type        = "zip"
  source_file = "${path.module}/files/user_policies_check.py"
  output_path = "${var.temp_artifacts_dir}/user_policies_check.zip"
}

resource "aws_lambda_function" "user_policies_check" {
  filename         = "${var.temp_artifacts_dir}/user_policies_check.zip"
  function_name    = "${var.resource_name_prefix}-user-policies-check"
  role             = "${aws_iam_role.user_policies_check.arn}"
  handler          = "user_policies_check.lambda_handler"
  source_code_hash = "${data.archive_file.user_policies_check.output_base64sha256}"
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
resource "aws_cloudwatch_event_rule" "user_policies_check" {
  name                = "${var.resource_name_prefix}-user-policies-check"
  description         = "remove expiring access keys"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "user_policies_check" {
  rule      = "${aws_cloudwatch_event_rule.user_policies_check.name}"
  target_id = "${var.resource_name_prefix}-user-policies-check"
  arn       = "${aws_lambda_function.user_policies_check.arn}"
}

resource "aws_lambda_permission" "user_policies_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.user_policies_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.user_policies_check.arn}"
}

## /Schedule the lambda function
# /AccessKey age check and delete function

