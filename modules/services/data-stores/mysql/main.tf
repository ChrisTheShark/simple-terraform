resource "aws_db_instance" "db" {
  instance_class    = "db.t2.micro"
  engine            = "mysql"
  allocated_storage = 10
  name              = "${var.cluster_name}"
  username          = "admin"
  password          = "${var.db_password}"
}