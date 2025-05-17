resource "aws_ecs_cluster" "ecs-cluster" {
    name                            = "${var.vpc-name}-ecs-cluster"
    setting {
        name                        = "containerInsights"
        value                       = "disabled"
    }
}

resource "aws_ecs_cluster_capacity_providers" "ecs-fargate" {
    cluster_name                    = aws_ecs_cluster.ecs-cluster.name
    capacity_providers              = ["FARGATE"]
    default_capacity_provider_strategy {
        base                        = 1
        weight                      = 100
        capacity_provider           = "FARGATE"
    }
}

resource "aws_ecs_task_definition" "ecs-taskdef" {
    family                          = "${var.vpc-name}-ecs-taskdef"
    requires_compatibilities        = ["FARGATE"]
    network_mode                    = "awsvpc"
    cpu                             = 1024
    memory                          = 3072
    container_definitions = jsonencode([
        {
            name                    = "nginxhello"
            image                   = "nginxdemos/hello"
            essential               = true
            portMappings = [
                {
                    containerPort   = 80
                    hostPort        = 80
                    protocol        = "tcp"
                    appProtocol     = "http"
                    name            = "nginxhello-http"
                }
            ]
        }
    ])
    runtime_platform {
        operating_system_family     = "LINUX"
        cpu_architecture            = "X86_64"
    }
}

resource "aws_ecs_service" "ecs-service" {
    name                            = "${var.vpc-name}-ecs-service"
    cluster                         = aws_ecs_cluster.ecs-cluster.id
    task_definition                 = aws_ecs_task_definition.ecs-taskdef.arn
    desired_count                   = local.az-width
    availability_zone_rebalancing   = "ENABLED"
    launch_type                     = "FARGATE"
    deployment_circuit_breaker {
        enable                      = true
        rollback                    = true
    }
    network_configuration {
        subnets                     = [for subnet in aws_subnet.private_subnet : subnet.id]
        security_groups             = [aws_security_group.ecs.id]
        assign_public_ip            = false
    }
    load_balancer {
        target_group_arn            = aws_lb_target_group.lb-target.arn
        container_name              = "nginxhello"
        container_port              = 80
    }
}