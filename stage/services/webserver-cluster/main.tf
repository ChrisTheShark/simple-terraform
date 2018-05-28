provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "chrisd-terraform-state"
    key    = "state/stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-stage"
  instance_type          = "t2.micro"
  min_size               = "2"
  max_size               = "2"

  db_remote_state_bucket = "chrisd-terraform-state"
  db_remote_state_key    = "state/stage/services/data-stores/mysql/terraform.tfstate"
}