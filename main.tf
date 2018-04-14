# main.tf only contains shared resouces across the module for purpose even the best pracites says
# keep roles as small as possible and have three files main,variables,outputs.tf
# So, the motivation in here make the code easily readable.
# You can open the CIS Benchmark and go step by step to verify or understand how
# the every other section works.
# Also, another aventage of this is easy to update the module when the benchmark
# gets any updates
#
# So that, we decided to break down the module into files per section.

# every lambda function uses this assume role policy
data "template_file" "iam_lambda_assume_role_policy" {
  template = "${file("${path.module}/templates/iam_lambda_assume_role_policy.json.tpl")}"
}
