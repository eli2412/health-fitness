resource "aws_db_instance" "health_rds" {
  allocated_storage    = 10
  db_name              = "health-fitnes-rds"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "workout123"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}