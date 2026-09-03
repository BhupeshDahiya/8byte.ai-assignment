resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/staging/db"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    PG_DB       = aws_db_instance.postgressql.db_name
    PG_USER     = aws_db_instance.postgressql.username
    PG_PASSWORD = random_password.db_password.result
    PG_HOST     = aws_db_instance.postgressql.address
    PG_SSL      = "true"
  })
}
# To get secret value = aws secretsmanager get-secret-value --secret-id 8byte-devops-assignment/staging/db --region us-east-1

