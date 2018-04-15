# IAM Instance Profile check for instances
## IAM Policy
data "template_file" "ec2_instances_iam_role_check_policy" {
  template = "${file("${path.module}/templates/lambda_ec2_instances_iam_role_check_policy.json.tpl")}"
}

resource "aws_iam_role" "ec2_instances_iam_role_check" {
  name               = "${var.resource_name_prefix}-ec2-instances-iam-role-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "ec2_instances_iam_role_check" {
  name   = "${var.resource_name_prefix}-lambda-ec2-instances-iam-role-check"
  role   = "${aws_iam_role.ec2_instances_iam_role_check.id}"
  policy = "${data.template_file.ec2_instances_iam_role_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "ec2_instances_iam_role_check" {
  type        = "zip"
  source_file = "${path.module}/files/ec2_instances_iam_role_check.py"
  output_path = "${var.temp_artifacts_dir}/ec2_instances_iam_role_check.zip"
}

resource "aws_lambda_function" "ec2_instances_iam_role_check" {
  filename         = "${var.temp_artifacts_dir}/ec2_instances_iam_role_check.zip"
  function_name    = "${var.resource_name_prefix}-ec2-instances-iam-role-check"
  role             = "${aws_iam_role.ec2_instances_iam_role_check.arn}"
  handler          = "ec2_instances_iam_role_check.lambda_handler"
  source_code_hash = "${data.archive_file.ec2_instances_iam_role_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = {
      DRY_RUN = "${var.lambda_dry_run}"
    }
  }

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "ec2_instances_iam_role_check" {
  name                = "${var.resource_name_prefix}-ec2-instances-iam-role-check"
  description         = "remove expiring access keys"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "ec2_instances_iam_role_check" {
  rule      = "${aws_cloudwatch_event_rule.ec2_instances_iam_role_check.name}"
  target_id = "${var.resource_name_prefix}-ec2-instances-iam-role-check"
  arn       = "${aws_lambda_function.ec2_instances_iam_role_check.arn}"
}

resource "aws_lambda_permission" "ec2_instances_iam_role_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ec2_instances_iam_role_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.ec2_instances_iam_role_check.arn}"
}

## /Schedule the lambda function
# /IAM Instance Profile check for instances

