# Dead Letter Queue
resource "aws_sqs_queue" "donations_dlq" {
  name                      = "solidarytech-donations-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 dias

  tags = merge(var.tags, { Name = "solidarytech-donations-dlq-${var.environment}" })
}

# Fila principal
resource "aws_sqs_queue" "donations" {
  name                       = "solidarytech-donations-${var.environment}"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 dia

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.donations_dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(var.tags, { Name = "solidarytech-donations-${var.environment}" })
}
