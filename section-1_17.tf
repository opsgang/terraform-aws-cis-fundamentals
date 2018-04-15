data "aws_billing_service_account" "main" {}

data "template_file" "billing_s3_bucket_policy" {
  template = "${file("${path.module}/templates/billing_s3_bucket_policy.json.tpl")}"

  vars {
    bucket_name                     = "${var.billing_s3_bucket_name != "" ? "${var.billing_s3_bucket_name}" : "${var.resource_name_prefix}-billing-logs"}"
    aws_billing_service_account_arn = "${data.aws_billing_service_account.main.arn}"
  }
}

resource "aws_s3_bucket" "billing_logs" {
  bucket = "${var.billing_s3_bucket_name != "" ? "${var.billing_s3_bucket_name}" : "${var.resource_name_prefix}-billing-logs"}"
  acl    = "private"

  policy = "${var.billing_s3_bucket_policy != "" ? "${var.billing_s3_bucket_policy}" : "${data.template_file.billing_s3_bucket_policy.rendered}"}"
}
