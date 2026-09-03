resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets
}
resource "aws_db_instance" "postgressql" {
  allocated_storage      = 10
  engine                 = "postgres"
  db_name                = "postgres"
  username               = "bhupesh"  
  password               = random_password.db_password.result
  engine_version         = "18.4"
  instance_class         = "db.t3.micro"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
}
resource "random_password" "db_password" {
  length  = 32
  special = false
}