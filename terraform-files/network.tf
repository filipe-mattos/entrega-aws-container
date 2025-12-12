data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_route_table" "default" {
  vpc_id = data.aws_vpc.vpc.id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow HTTP inbound to ALB"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4200 # Porta padrão do Angular CLI
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Angular dev server"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_security_group" "ecs_sg" {
  name        = "${local.name_prefix}-ecs-sg"
  vpc_id      = data.aws_vpc.vpc.id
  description = "Allow necessary traffic for ECS tasks"

  ingress {
    description     = "Allow ALB to frontend"
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4200 # Porta padrão do Angular CLI
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Angular dev server"
  }

  egress {
    description = "Allow tasks to access outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-ecs-sg" }
}

resource "aws_lb" "alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "frontend" {
  name        = "${local.name_prefix}-tg-frontend"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
