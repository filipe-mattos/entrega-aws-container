locals {
  name_prefix = var.project_name

  container_definitions = [
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
        }
      ]
      
      # Example env var to allow frontend to call backend at localhost:<backend_port>
      environment = [
        { name = "BACKEND_URL", value = "http://localhost:${var.backend_container_port}" }
      ]
    },
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DATABASE_URL", value = "postgresql+psycopg2://postgres:postgres@db:5432/localoucos" }
      ]
     
    },
    {
      name  = "database"
      image = "postgres:16"
      environment = [
        { name = "POSTGRES_USER", value = "postgres" },
        { name = "POSTGRES_PASSWORD", value = "postgres" },
        { name = "POSTGRES_DB", value = "localoucos" }
      ]
      portMappings = [{ containerPort = 5432 }]
    }
  ]
}
