{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${bucket_name}",
      "Principal": {
        "AWS": [
          "${aws_billing_service_account_arn}"
        ]
      }
    },
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${bucket_name}/*",
      "Principal": {
        "AWS": [
          "${aws_billing_service_account_arn}"
        ]
      }
    }
  ]
}
