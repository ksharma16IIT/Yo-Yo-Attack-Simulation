variable "project_name"{
    type = string
    description = "Name of the project or tool."
}

variable "ec2_config"{
    type = map(string)

    default = {
        ami_id = "ami-02238ac43d6385ab3" #Default to Amazon Linux 2 (us-east-2)
        instance_type = "t2.micro" #Default to t2.micro
        desired_count = 1
        max_count = 5
        host_port = 80
    }
}

variable "network_config" {
  type = object({
    security_group = string,
    subnet = list(string),
    vpc_id = string
  })

  default = {
    security_group = "sg-0d00cc07f429d231e"
    subnet = ["subnet-045108ca90b62a1ba","subnet-09e4c87429e8c542f"]
    vpc_id = "vpc-06ef4332659377f72"
  }
}
