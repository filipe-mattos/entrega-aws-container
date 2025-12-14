provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "localoucos-cluster"
}

resource "aws_security_group" "sg" {
  name   = "localoucos-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "localoucos-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "filipemagioni/frontendlocadora:latest"
      essential = true
      portMappings = [
        {
          containerPort = 4200
        }
      ]
      
    },
    {
      name      = "backend"
      image     = "danieldonateli/locadora-api-backend:latest"
      essential = false
      portMappings = [
        {
          containerPort = 8000
        }
      ]
      environment = [
        { name = "DATABASE_URL", value = "postgresql+psycopg2://postgres:postgres@localhost:5432/localoucos" }
      ]
    },
    {
      name      = "database"
      image     = "postgres:16"
      essential = true
      portMappings = [
        {
          containerPort = 5432
        }
      ]
      environment = [
        { name = "POSTGRES_USER", value = "postgres" },
        { name = "POSTGRES_PASSWORD", value = "postgres" },
        { name = "POSTGRES_DB", value = "localoucos" }
      ]
    },
  ])
}

resource "aws_ecs_service" "service" {
  name            = "localoucos-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}