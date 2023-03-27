terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.12.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"

}

module "application_autoscaling" {
  source = "./modules/ec2"
  project_name = "YoYo-Application"
}

variable "node_size" {
    description = "Size of total nodes"
    default = 2
}

variable "loadtest_dir_source" {
    default = "DDOS/"
}

variable "locust_plan_filename" {
    default = "locustfile.py"
}

variable "subnet_name" {
    default = "subnet-1"
    description = "Subnet name"
}

module "loadtest" {
    
    # https://registry.terraform.io/modules/marcosborges/loadtest-distribuited/aws/latest
    source  = "marcosborges/loadtest-distribuited/aws"

    name = "provision-name"
    nodes_size = var.node_size
    executor = "locust"
    loadtest_dir_source = var.loadtest_dir_source
    nodes_intance_type = "t2.micro"
    leader_instance_type = "t2.micro"
    
    # LEADER ENTRYPOINT
    # LEADER ENTRYPOINT
    loadtest_entrypoint = <<-EOT
        nohup locust \
            -f ${var.locust_plan_filename} \
            --web-port=8080 \
            --expect-workers=${var.node_size} \
            --master > locust-leader.out 2>&1 &
    EOT
    
    # NODES ENTRYPOINT
    node_custom_entrypoint = <<-EOT
        nohup locust \
            -f ${var.locust_plan_filename} \
            --worker \
            --master-host={LEADER_IP} > locust-worker.out 2>&1 &
    EOT

    subnet_id = data.aws_subnet.current.id
    locust_plan_filename = var.locust_plan_filename
    ssh_export_pem = false

}

data "aws_subnet" "current" {
    filter {
        name   = "tag:Name"
        values = [var.subnet_name]
    }
}

output "leader_public_ip" {
    value = module.loadtest.leader_public_ip
    description = "The public IP address of the leader server instance."
}

output "leader_private_ip" {
    value = module.loadtest.leader_private_ip
    description = "The private IP address of the leader server instance."
}

output "nodes_public_ip" {
    value = module.loadtest.nodes_public_ip
    description = "The public IP address of the nodes instances."
}

output "nodes_private_ip" {
    value = module.loadtest.nodes_private_ip
    description = "The private IP address of the nodes instances."
}

output "dashboard_url" {
    value = "http://${coalesce(module.loadtest.leader_public_ip, module.loadtest.leader_private_ip)}"
    description = "The URL of the Locust UI."
}
