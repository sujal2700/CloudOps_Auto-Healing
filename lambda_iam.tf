# 1. IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_healing_role" {
  name = "cloudops-lambda-healing-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 2. IAM Policy granting permissions to read logs, terminate instances, and run instances
resource "aws_iam_policy" "lambda_healing_policy" {
  name        = "cloudops-lambda-healing-policy"
  description = "Allows Lambda to manage EC2 instances for auto-healing and write logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "ec2:RunInstances",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_healing_role.name
  policy_arn = aws_iam_policy.lambda_healing_policy.arn
}

# 4. Package the Python Lambda script into a zip file automatically
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# 5. Deploy the AWS Lambda Function
resource "aws_lambda_function" "auto_healer" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "cloudops-auto-healer"
  role          = aws_iam_role.lambda_healing_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      REPLACEMENT_AMI_ID    = data.aws_ami.amazon_linux.id
      REPLACEMENT_SUBNET_ID = aws_subnet.public.id
      REPLACEMENT_SG_ID     = aws_security_group.instance_sg.id
    }
  }
}

# 6. Give SNS permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_healer.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.healing_topic.arn
}

# 7. Subscribe the Lambda function to the SNS Healing Topic
resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.healing_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.auto_healer.arn
}