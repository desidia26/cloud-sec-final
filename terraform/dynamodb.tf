resource "aws_dynamodb_table" "ip_table" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ip"
  attribute {
    name = "ip"
    type = "S"
  }
  ttl {
    attribute_name = "expire_time"
    enabled        = true
  }
}