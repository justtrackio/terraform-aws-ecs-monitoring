variable "cadvisor_cpu" {
  type        = number
  description = "Number of CPU units to reserve for the container"
  default     = 100
}

variable "cadvisor_registry" {
  type        = string
  description = "cAdvisor registry to be used"
  default     = "gcr.io"
}

variable "cadvisor_repository" {
  type        = string
  description = "cAdvisor repository to be used"
  default     = "cadvisor/cadvisor"
}

variable "cadvisor_version" {
  type        = string
  description = "cAdvisor version to be deployed"
  default     = "v0.47.0"
}

variable "container_memory_reservation" {
  type        = number
  description = "The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  default     = 128
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ECS cluster ARN where this service will be deployed"
}

variable "environment_variables" {
  type        = map(string)
  description = "The environment variables to pass to the container. This is a map of string: {key: value}. map_environment overrides environment"
  default     = null
}

variable "label_orders" {
  type = object({
    cloudwatch = optional(list(string)),
    ecs        = optional(list(string)),
    iam        = optional(list(string)),
    vpc        = optional(list(string))
  })
  default     = {}
  description = "Overrides the `labels_order` for the different labels to modify ID elements appear in the `id`"
}

variable "log_retention_in_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group."
  default     = 1
}

variable "node_exporter_cpu" {
  type        = number
  description = "Number of CPU units to reserve for the container"
  default     = 100
}

variable "node_exporter_registry" {
  type        = string
  description = "Node exporter registry to be used"
  default     = "quay.io"
}

variable "node_exporter_repository" {
  type        = string
  description = "Node exporter repository to be used"
  default     = "prometheus/node-exporter"
}

variable "node_exporter_version" {
  type        = string
  description = "Node exporter version to be deployed"
  default     = "v1.5.0"
}

variable "task_cpu" {
  type        = number
  description = "Number of CPU units to reserve for the container"
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "The amount of memory (in MiB) used by the task. If using Fargate launch type `task_memory` must match [supported cpu value](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size)"
  default     = 512
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where resources are created"
}
