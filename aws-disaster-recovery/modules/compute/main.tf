terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_launch_template" "this" {
  name_prefix   = "dr-${var.name}-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eux
    dnf install -y nginx
    cat > /usr/share/nginx/html/index.html <<HTML
    <html>
      <body>
        <h1>AWS Disaster Recovery</h1>
        <p>Region role: ${var.name}</p>
        <p>Hostname: $(hostname)</p>
      </body>
    </html>
    HTML
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "dr-${var.name}-app"
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "dr-${var.name}-asg"
  min_size            = var.min_size
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnets

  target_group_arns = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dr-${var.name}-app"
    propagate_at_launch = true
  }
}
