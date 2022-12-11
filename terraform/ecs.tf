
resource "aws_ecs_cluster" "go-server-cluster" {
  name       = "${terraform.workspace}-go-servers"
  depends_on = [null_resource.push_images]
}

resource "aws_ecs_task_definition" "victim_task" {
  family                   = "${terraform.workspace}-victim"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/victim:${var.tag}",
    "cpu": 1024,
    "memory": 2048,
    "name": "victim",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${terraform.workspace}-${var.log_group_name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_task_definition" "attacker_task" {
  family                   = "${terraform.workspace}-attacker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/attacker:${var.tag}",
    "cpu": 1024,
    "memory": 2048,
    "name": "attacker",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ],
    "environment": [
      {
        "name": "VICTIM_URL", 
        "value": "${var.victim_url}.${terraform.workspace}.cloud.sec.final:8080"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${terraform.workspace}-${var.log_group_name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "victim_service" {
  name            = "${terraform.workspace}-victim_service"
  cluster         = aws_ecs_cluster.go-server-cluster.id
  task_definition = aws_ecs_task_definition.victim_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.task_sg.id]
    subnets         = [aws_subnet.private[0].id]
  }
  service_registries {
    registry_arn = aws_service_discovery_service.victim_service_discovery_service.arn
  }
}


resource "aws_ecs_service" "attacker_service" {
  name            = "${terraform.workspace}-attacker_service"
  cluster         = aws_ecs_cluster.go-server-cluster.id
  task_definition = aws_ecs_task_definition.attacker_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.task_sg.id]
    subnets         = [aws_subnet.private[1].id]
  }
  depends_on = [aws_service_discovery_service.victim_service_discovery_service]
}