data "aws_vpcs" "default" {
  tags = {
    Name = "example"
  }
}

data "aws_ecs_cluster" "default" {
  cluster_name = "example"
}

module "ecs_monitoring" {
  source          = "../.."
  stage           = "ecs"
  name            = "monitoring"
  ecs_cluster_arn = data.aws_ecs_cluster.default.arn
  vpc_id          = data.aws_vpcs.default.id
}
