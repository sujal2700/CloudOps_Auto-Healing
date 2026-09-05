# 1. Create an SNS Topic that will receive the failure alert
resource "aws_sns_topic" "healing_topic" {
  name = "cloudops-healing-topic"
}

# 2. Create a CloudWatch Metric Alarm for Status Check Failures
# This triggers if the instance fails both system and instance status checks for 2 consecutive periods (2 minutes)
resource "aws_cloudwatch_metric_alarm" "ec2_health_alarm" {
  alarm_name          = "cloudops-ec2-health-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Triggered when EC2 instance status check fails"
  
  dimensions = {
    InstanceId = aws_instance.primary.id
  }

  # Wire the alarm to send a notification to our SNS topic when it enters ALARM state
  alarm_actions = [aws_sns_topic.healing_topic.arn]
}

# Output the SNS Topic ARN so our Lambda function can subscribe to it later
output "sns_topic_arn" {
  value       = aws_sns_topic.healing_topic.arn
  description = "ARN of the SNS healing topic"
}
