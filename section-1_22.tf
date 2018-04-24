# Support group check and delete function
## IAM Policy
data "template_file" "support_group_check_policy" {
  template = "${file("${path.module}/templates/lambda_support_group_check_policy.json.tpl")}"
}

resource "aws_iam_role" "support_group_check" {
  name               = "${var.resource_name_prefix}-support-group-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "support_group_check" {
  name   = "${var.resource_name_prefix}-lambda-support-group-check"
  role   = "${aws_iam_role.support_group_check.id}"
  policy = "${data.template_file.support_group_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "support_group_check" {
  type        = "zip"
  source_file = "${path.module}/files/support_group_check.py"
  output_path = "${var.temp_artifacts_dir}/support_group_check.zip"
}

resource "aws_lambda_function" "support_group_check" {
  filename         = "${var.temp_artifacts_dir}/support_group_check.zip"
  function_name    = "${var.resource_name_prefix}-support-group-check"
  role             = "${aws_iam_role.support_group_check.arn}"
  handler          = "support_group_check.lambda_handler"
  source_code_hash = "${data.archive_file.support_group_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "support_group_check" {
  name                = "${var.resource_name_prefix}-support-group-check"
  description         = "remove expiring access keys"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "support_group_check" {
  rule      = "${aws_cloudwatch_event_rule.support_group_check.name}"
  target_id = "${var.resource_name_prefix}-support-group-check"
  arn       = "${aws_lambda_function.support_group_check.arn}"
}

resource "aws_lambda_permission" "support_group_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.support_group_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.support_group_check.arn}"
}

## /Schedule the lambda function
# /Support group check and delete function

