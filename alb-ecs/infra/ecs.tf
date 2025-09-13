resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-ecs-cluster"
  tags = local.tags
}

resource "aws_ecs_service" "this" {
  name                              = "${var.prefix}-ecs-service"
  cluster                           = aws_ecs_cluster.this.id
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = 1
  enable_execute_command            = true
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs.id]
    subnets          = module.vpc.private_subnet_ids
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.http.arn
    container_name   = "${var.prefix}-ecs-container"
    container_port   = var.app_port
  }
  tags       = local.tags
  depends_on = [aws_acm_certificate_validation.alb, aws_lb.this, aws_lb_target_group.http, aws_lb_listener_rule.http]
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-task-def"
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      name   = "${var.prefix}-ecs-container"
      image  = "${aws_ecr_repository.app.repository_url}:${data.aws_ecr_image.app.image_tag}@${data.aws_ecr_image.app.image_digest}"
      cpu    = 512
      memory = 1024
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]
      linuxParameters = {
        initProcessEnabled = true
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "${var.prefix}/ecs"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  tags = local.tags
}

resource "aws_iam_role" "ecs_task" {
  name = "${var.prefix}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags
}


resource "aws_iam_role_policy" "ecs_task" {
  name = "${var.prefix}-ecs-task-policy"
  role = aws_iam_role.ecs_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:DescribeLogStrams",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ecs_task_exec" {
  name = "${var.prefix}-ecs-task-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec" {
  for_each = toset(
    concat(
      [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
      ],
      var.enable_execute_command ? [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
      ] : []
    )
  )

  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = each.value
}

resource "aws_security_group" "ecs" {
  name   = "${var.prefix}-ecs-sg"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "ecs_app" {
  security_group_id            = aws_security_group.ecs.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_ecr_repository" "app" {
  name                 = "${var.prefix}-app-repo"
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = var.delete_app_ecr
  tags         = local.tags
}

data "archive_file" "app" {
  type        = "zip"
  source_dir  = "${path.module}/../app"
  output_path = "${path.module}/app.zip"
}

resource "null_resource" "push_app_image" {
  triggers = {
    app_code_change = data.archive_file.app.output_base64sha256
    script_hash     = sha1(file("${path.module}/push_image.sh"))
  }
  provisioner "local-exec" {
    command = <<EOT
      chmod +x ${path.module}/push_image.sh
      ${path.module}/push_image.sh ${aws_ecr_repository.app.repository_url} ${var.aws_region} ${path.module}
    EOT
  }
  depends_on = [aws_ecr_repository.app]
}

data "aws_ecr_image" "app" {
  repository_name = aws_ecr_repository.app.name
  image_tag       = "latest"
  depends_on      = [null_resource.push_app_image]
}
