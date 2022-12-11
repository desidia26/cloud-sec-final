resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${terraform.workspace}_ecs_task_execution_role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
resource "aws_iam_role" "ecs_task_role" {
  name = "${terraform.workspace}_ecs_task_role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "cloudwatch-lambda-role" {
  name = "${terraform.workspace}-test-cloudwatch-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "logs" {
  name = "lambda-logs"
  role = aws_iam_role.cloudwatch-lambda-role.name
  policy = jsonencode({
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "ec2:DescribeNetworkAcls",
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "ec2:CreateNetworkAclEntry",
          "sns:Publish"
        ],
        "Resource" : [
          "arn:aws:logs:*:*:*",
          "${aws_dynamodb_table.ip_table.arn}",
          "${aws_network_acl.victim_acl.arn}",
          "${aws_sns_topic.attack_topic.arn}"
        ]
      }
    ]
  })
}