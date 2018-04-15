resource "aws_iam_account_password_policy" "cis" {
  # 1.5
  require_uppercase_characters = "${var.iam_require_uppercase_characters}"

  # 1.6
  require_lowercase_characters = "${var.iam_require_lowercase_characters}"

  # 1.7
  require_symbols = "${var.iam_require_symbols}"

  # 1.8
  require_numbers = "${var.iam_require_numbers}"

  # 1.9
  minimum_password_length = "${var.iam_minimum_password_length}"

  # 1.10
  password_reuse_prevention = "${var.iam_password_reuse_prevention}"

  # 1.11
  max_password_age = "${var.iam_max_password_age}"

  allow_users_to_change_password = "${var.iam_allow_users_to_change_password}"

  hard_expiry = "${var.iam_hard_expiry}"
}

# Password policy check function
## IAM Policy
data "template_file" "password_policy_check_policy" {
  template = "${file("${path.module}/templates/lambda_password_policy_check_policy.json.tpl")}"
}

resource "aws_iam_role" "password_policy_check" {
  name               = "${var.resource_name_prefix}-password-policy-check"
  assume_role_policy = "${data.template_file.iam_lambda_assume_role_policy.rendered}"
}

resource "aws_iam_role_policy" "password_policy_check" {
  name   = "${var.resource_name_prefix}-lambda-password-policy-check"
  role   = "${aws_iam_role.password_policy_check.id}"
  policy = "${data.template_file.password_policy_check_policy.rendered}"
}

## /IAM Policy

## Create the function
data "archive_file" "password_policy_check" {
  type        = "zip"
  source_file = "${path.module}/files/password_policy_check.py"
  output_path = "${var.temp_artifacts_dir}/password_policy_check.zip"
}

resource "aws_lambda_function" "password_policy_check" {
  filename         = "${var.temp_artifacts_dir}/password_policy_check.zip"
  function_name    = "${var.resource_name_prefix}-password-policy-check"
  role             = "${aws_iam_role.password_policy_check.arn}"
  handler          = "password_policy_check.lambda_handler"
  source_code_hash = "${data.archive_file.password_policy_check.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = {
      REQUIRE_UPPERCASE_CHARACTERS   = "${var.iam_require_uppercase_characters}"
      REQUIRE_LOWERCASE_CHARACTERS   = "${var.iam_require_lowercase_characters}"
      REQUIRE_SYMBOLS                = "${var.iam_require_symbols}"
      REQUIRE_NUMBERS                = "${var.iam_require_numbers}"
      MINIMUM_PASSWORD_LENGTH        = "${var.iam_minimum_password_length}"
      PASSWORD_REUSE_PREVENTION      = "${var.iam_password_reuse_prevention}"
      MAX_PASSWORD_AGE               = "${var.iam_max_password_age}"
      ALLOW_USERS_TO_CHANGE_PASSWORD = "${var.iam_allow_users_to_change_password}"
      HARD_EXPIRY                    = "${var.iam_hard_expiry}"
    }
  }

  tags = "${var.tags}"
}

## /Create the function

## Schedule the lambda function
resource "aws_cloudwatch_event_rule" "password_policy_check" {
  name                = "${var.resource_name_prefix}-password-policy-check"
  description         = "Check if password policy is in desired state"
  schedule_expression = "${var.lambda_cron_schedule}"
}

resource "aws_cloudwatch_event_target" "password_policy_check" {
  rule      = "${aws_cloudwatch_event_rule.password_policy_check.name}"
  target_id = "${var.resource_name_prefix}-password-policy-check"
  arn       = "${aws_lambda_function.password_policy_check.arn}"
}

resource "aws_lambda_permission" "password_policy_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.password_policy_check.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.password_policy_check.arn}"
}

## /Schedule the lambda function
# /Password policy check function

