provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "chrisd-terraform-state"
    key    = "state/prod/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  instance_type          = "t2.micro" // free tier eligible, prod could use m4.large or something else
  min_size               = "2"
  max_size               = "10"

  db_remote_state_bucket = "chrisd-terraform-state"
  db_remote_state_key    = "state/prod/services/data-stores/mysql/terraform.tfstate"
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"

  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-at-night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = "${module.webserver_cluster.asg_name}"
}