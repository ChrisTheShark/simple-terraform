provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "chrisd-terraform-state"
    key    = "state/prod/services/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
  }
}

module "db_instance" {
  source = "../../../../modules/services/data-stores/mysql"

  cluster_name = "dbprod"
  db_password  = "password1"
}