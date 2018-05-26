provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "chrisd-terraform-state"
    key    = "state/services/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
    workspace_key_prefix = "stage"
  }
}

resource "aws_db_instance" "example" {
  instance_class    = "db.t2.micro"
  engine            = "mysql"
  allocated_storage = 10
  name              = "example_database"
  username          = "admin"
  password          = "${var.db_password}"
}