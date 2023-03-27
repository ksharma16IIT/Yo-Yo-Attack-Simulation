

resource "aws_launch_configuration" "ec2_launch_config" {
    name_prefix          = "${var.project_name}-lc"
    image_id             = var.ec2_config.ami_id
    # iam_instance_profile = var.ec2_config.instance_profile_role
    security_groups      = [var.network_config.security_group]
    user_data            = filebase64("${path.module}/flask-api-nginx.sh")
    instance_type        = var.ec2_config.instance_type
}

resource "aws_autoscaling_group" "ec2_asg" {
    name                      = "${var.project_name}-asg"
    vpc_zone_identifier       = var.network_config.subnet
    launch_configuration      = aws_launch_configuration.ec2_launch_config.name

    desired_capacity          = var.ec2_config.desired_count
    min_size                  = 1
    max_size                  = var.ec2_config.max_count
    health_check_grace_period = 30
    health_check_type         = "EC2"
    default_cooldown = 30
    target_group_arns = [aws_lb_target_group.lb-target.arn]
    
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_policy" "bat" {
  name                   = "alb-policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 100
    predefined_metric_specification {
      predefined_metric_type = "ALBTargetGroupRequestCount"
    }
  }
  autoscaling_group_name = aws_autoscaling_group.ec2_asg.name
}


resource "aws_lb_target_group" "lb-target" {
  name_prefix = substr(var.project_name, 0, 6)
  depends_on  = [
    aws_lb.lb]
  port        = var.ec2_config.host_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id = var.network_config.vpc_id
  deregistration_delay = 20
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    interval            = 5
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
  }
}

resource "aws_lb" "lb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.network_config.subnet

  enable_deletion_protection = false

}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.ec2_config.host_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target.arn
  }
}