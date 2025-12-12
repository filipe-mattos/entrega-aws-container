variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ecs-full-stack"
}

# Docker Hub images (set to your repos)
variable "frontend_image" {
  type    = string
  default = "filipemagioni/frontendlocadora:latest"
}

variable "frontend_container_port" {
  type    = number
  default = 4200
}

variable "backend_image" {
  type    = string
  default = "danieldonateli/locadora-api-backend:latest"
}

variable "backend_container_port" {
  type    = number
  default = 8000
}

variable "desired_count" {
  type    = number
  default = 1
}

# Size
variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_secret_key" {
  type    = string
  default = ""
}

variable "aws_session_token" {
  type    = string
  default = ""
}
