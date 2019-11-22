module "service" {
  source = "./service.iac"

  aws_vpc_id              = var.aws_vpc_id
  aws_vpc_subnets_public  = var.aws_vpc_subnets_public
  aws_vpc_subnets_private = var.aws_vpc_subnets_private


  service_settings = {
    "evt_srv_002" = {
      external = true
    }
  }

  service_apps = {
    "api_123" = {
      stream_name      = "evt_stream_1"
      shard_count      = "3"
      retention_period = "48"
    }
  }

}
