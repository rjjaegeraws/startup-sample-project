
resource "aws_dynamodb_table" "startup_sample_table" {
  name           = var.db_name
  hash_key       = "id"
  read_capacity  = 5
  write_capacity = 5
  
  attribute {
    name = "id"
    type = "S"
  }

   tags = local.common_tags
}