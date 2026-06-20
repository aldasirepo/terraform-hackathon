resource "aws_sqs_queue" "donations_dlq" {
  name                      = "${var.project_name}-donations-dlq-${var.environment}"
  message_retention_seconds = 1209600
  tags                      = var.tags
}

resource "aws_sqs_queue" "donations" {
  name                       = "${var.project_name}-donations-${var.environment}"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.donations_dlq.arn
    maxReceiveCount     = 3
  })
  tags = var.tags
}
