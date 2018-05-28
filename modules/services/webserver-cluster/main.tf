data "aws_availability_zones" "all" {}
data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "${var.db_remote_state_bucket}"
    key    = "${var.db_remote_state_key}"
    region = "us-east-1"
  }
}
data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
    db_address  = "${data.terraform_remote_state.db.db_address}"
    db_port     = "${data.terraform_remote_state.db.db_port}"
  }
}

resource "aws_launch_configuration" "alc" {
  image_id             = "ami-40d28157"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.instance-group.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance-group" {
  name = "${var.cluster_name}-instance-group"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_http_inbound_instance" {
  security_group_id = "${aws_security_group.instance-group.id}"

  type      = "ingress"
  from_port = "${var.server_port}"
  to_port   = "${var.server_port}"
  protocol  = "tcp"
}

resource "aws_autoscaling_group" "asg" {
  launch_configuration = "${aws_launch_configuration.alc.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  load_balancers       = ["${aws_elb.elb-instance.name}"]
  health_check_type    = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key   = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "elb-instance" {
  name = "${var.cluster_name}-elb-instance"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]
  security_groups      = ["${aws_security_group.elb-group.id}"]

  listener {
    lb_port             = 80
    lb_protocol         = "http"
    instance_port       = "${var.server_port}"
    instance_protocol   = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb-group" {
  name = "${var.cluster_name}-elb-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  security_group_id = "${aws_security_group.elb-group.id}"

  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  security_group_id = "${aws_security_group.elb-group.id}"

  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "tcp"
}