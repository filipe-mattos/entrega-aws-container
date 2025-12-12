resource "aws_ecs_cluster" "cluster" {
  name = "${local.name_prefix}-cluster"
}

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)

  container_definitions = jsonencode(local.container_definitions)
}

resource "aws_ecs_service" "service" {
  name             = "${local.name_prefix}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]
}
