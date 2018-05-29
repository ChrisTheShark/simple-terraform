output "dns_name" {
  value = "${module.webserver_cluster.dns_name}"
}

output "asg_name" {
  value = "${module.webserver_cluster.asg_name}"
}