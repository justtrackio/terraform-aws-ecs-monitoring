module "cadvisor_label" {
  source  = "justtrackio/label/null"
  version = "0.26.0"

  attributes  = ["cadvisor"]
  label_order = var.label_orders.cloudwatch

  context = module.this.context
}

module "node_exporter_label" {
  source  = "justtrackio/label/null"
  version = "0.26.0"

  attributes  = ["node-exporter"]
  label_order = var.label_orders.cloudwatch

  context = module.this.context
}

resource "aws_cloudwatch_log_group" "node_exporter" {
  name              = module.node_exporter_label.id
  tags              = module.node_exporter_label.tags
  retention_in_days = var.log_retention_in_days
}

resource "aws_cloudwatch_log_group" "cadvisor" {
  name              = module.cadvisor_label.id
  tags              = module.cadvisor_label.tags
  retention_in_days = var.log_retention_in_days
}

module "node_exporter_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"

  interactive              = false
  readonly_root_filesystem = true
  container_name           = "node-exporter"
  container_image          = "${var.node_exporter_registry}/${var.node_exporter_repository}:${var.node_exporter_version}"
  mount_points = [
    {
      containerPath = "/host"
      sourceVolume  = "root"
      readOnly      = true
    }
  ]
  command = [
    "--path.rootfs=/host"
  ]
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.node_exporter_cpu
  map_environment              = var.environment_variables
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.node_exporter.name
      awslogs-region        = module.this.aws_region
      awslogs-stream-prefix = "ecs"
    }
  }
}

module "cadvisor_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"

  interactive              = false
  readonly_root_filesystem = true
  container_name           = "cadvisor"
  container_image          = "${var.cadvisor_registry}/${var.cadvisor_repository}:${var.cadvisor_version}"
  mount_points = [
    {
      containerPath = "/sys/fs/cgroup"
      sourceVolume  = "cgroup"
      readOnly      = true
    },
    {
      containerPath = "/rootfs"
      sourceVolume  = "root"
      readOnly      = true
    },
    {
      containerPath = "/var/run"
      sourceVolume  = "var_run"
      readOnly      = false
    },
    {
      containerPath = "/sys"
      sourceVolume  = "sys"
      readOnly      = true
    },
    {
      containerPath = "/var/lib/docker"
      sourceVolume  = "var_lib_docker"
      readOnly      = true
    },
    {
      containerPath = "/dev/disk"
      sourceVolume  = "dev_disk"
      readOnly      = true
    }
  ]
  privileged = true
  linux_parameters = {
    capabilities = {
      add  = null
      drop = null
    }
    devices = [
      {
        containerPath = null
        hostPath      = "/dev/kmsg"
        permissions   = ["read"]
      }
    ]
    initProcessEnabled = null
    maxSwap            = null
    sharedMemorySize   = null
    swappiness         = null
    tmpfs              = []
  }
  command = [
    "--port=8001",
    "--store_container_labels=false",
    "--enable_load_reader=true",
    "--whitelisted_container_labels=com.amazonaws.ecs.cluster,com.amazonaws.ecs.task-definition-family,com.amazonaws.ecs.container-name,com.amazonaws.ecs.task-definition-version",
    "--docker_only=true",
    "--disable_metrics=advtcp,cpuset,cpu_topology,disk,hugetlb,memory_numa,process,referenced_memory,resctrl,sched,tcp,udp",
    "--housekeeping_interval=2s"
  ]
  container_cpu                = var.cadvisor_cpu
  container_memory_reservation = var.container_memory_reservation
  map_environment = merge(
    var.environment_variables,
    {
      CADVISOR_HEALTHCHECK_URL = "http://localhost:8001/healthz"
    }
  )
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.cadvisor.name
      awslogs-region        = module.this.aws_region
      awslogs-stream-prefix = "ecs"
    }
  }
}

module "ecs_service_task" {
  source  = "justtrackio/ecs-alb-service-task/aws"
  version = "1.5.0"

  container_definition_json      = "[${module.node_exporter_definition.json_map_encoded},${module.cadvisor_definition.json_map_encoded}]"
  ecs_cluster_arn                = var.ecs_cluster_arn
  ignore_changes_task_definition = var.ignore_changes_task_definition
  launch_type                    = "EC2"
  scheduling_strategy            = "DAEMON"
  task_cpu                       = var.task_cpu
  task_memory                    = var.task_memory
  network_mode                   = "host"
  docker_volumes = [
    {
      host_path                   = "/"
      name                        = "root"
      docker_volume_configuration = []
    },
    {
      host_path                   = "/var/run"
      name                        = "var_run"
      docker_volume_configuration = []
    },
    {
      host_path                   = "/sys"
      name                        = "sys"
      docker_volume_configuration = []
    },
    {
      host_path                   = "/var/lib/docker"
      name                        = "var_lib_docker"
      docker_volume_configuration = []
    },
    {
      host_path                   = "/dev/disk"
      name                        = "dev_disk"
      docker_volume_configuration = []
    },
    {
      host_path                   = "/sys/fs/cgroup"
      name                        = "cgroup"
      docker_volume_configuration = []
    }
  ]
  vpc_id         = var.vpc_id
  propagate_tags = "SERVICE"

  label_orders = var.label_orders
  context      = module.this.context
}
