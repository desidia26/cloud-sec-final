resource "aws_cloudwatch_log_group" "services_log_group" {
  name = "${terraform.workspace}-${var.log_group_name}"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch-lambda-subscription" {
  name            = "${terraform.workspace}-cloudwatch-lambda-subscription"
  log_group_name  = aws_cloudwatch_log_group.services_log_group.name
  filter_pattern  = "Failed login attempt from ip"
  destination_arn = aws_lambda_function.cloudwatch-sub-lambda.arn
}