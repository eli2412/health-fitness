resource "aws_db_instance" "fitnessRDS" {
  allocated_storage    = 10
  db_name              = "fitnessrds"
  engine               = "postgres"
  engine_version       = "15.4"
  identifier           = "fitness-postgres-db"
  instance_class       = "db.t3.micro"
  username             = "admin1"
  password             = "workout123"
  publicly_accessible  = true
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

    tags = {
    Name = "fitnessrds"
  }
}