output "sqs_queue_url" {
  value = aws_sqs_queue.donations.url
}
output "sqs_queue_arn" {
  value = aws_sqs_queue.donations.arn
}
output "dlq_url" {
  value = aws_sqs_queue.donations_dlq.url
}
