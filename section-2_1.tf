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
