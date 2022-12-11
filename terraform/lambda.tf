data "archive_file" "lambda_zip_file_int" {
  type        = "zip"
  output_path = "${path.module}/lambda-resources/index.zip"
  source {
    content  = file("${path.module}/lambda-resources/index.js")
    filename = "index.js"
  }
}

resource "aws_lambda_function" "cloudwatch-sub-lambda" {
  function_name    = "${terraform.workspace}-cloudwatch-subscription-lambda"
  filename         = data.archive_file.lambda_zip_file_int.output_path
  source_code_hash = data.archive_file.lambda_zip_file_int.output_base64sha256
  handler          = "index.handler"
  role             = aws_iam_role.cloudwatch-lambda-role.arn
  memory_size      = "128"
  runtime          = "nodejs14.x"
  environment {
    variables = {
      TABLE_NAME = "${var.table_name}"
      ACL_ID     = "${aws_network_acl.victim_acl.id}"
      EMAIL_ADDR = "${var.email}"
      TOPIC_ARN  = "${aws_sns_topic.attack_topic.arn}"
    }
  }
}

resource "aws_lambda_permission" "allow-cloudwatch" {
  statement_id  = "${terraform.workspace}-allow-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch-sub-lambda.arn
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.services_log_group.arn}:*"
}