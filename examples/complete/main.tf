variable "profile" {
  default = "default"
}

variable "region" {
  default = "cn-beijing"
}

provider "alicloud" {
  region  = var.region
  profile = var.profile
}

#############################################################
# Data sources to get VPC, vswitch details
#############################################################
data "alicloud_vpcs" "default" {
  is_default = true
}

data "alicloud_vswitches" "default" {
  ids = [data.alicloud_vpcs.default.vpcs.0.vswitch_ids.0]
}

data "alicloud_instance_types" "this" {
  cpu_core_count    = 1
  memory_size       = 2
  availability_zone = data.alicloud_vswitches.default.vswitches.0.zone_id
}

#############################################################
# Create a new security and open 80 22 port
#############################################################
module "security_group" {
  source              = "alibaba/security-group/alicloud"
  region              = var.region
  profile             = var.profile
  vpc_id              = data.alicloud_vpcs.default.ids.0
  name                = "tensorflow-1"
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp","http-80-tcp"]
}

module "market-tensorflow" {
  source                     = "../.."
  region                     = var.region
  profile                    = var.profile
  ecs_instance_name          = "tensorflow-instance"
  ecs_instance_password      = "YourPassword123"
  ecs_instance_type          = data.alicloud_instance_types.this.ids.0
  system_disk_category       = "cloud_efficiency"
  security_group_ids         = [module.security_group.this_security_group_id]
  vswitch_id                 = data.alicloud_vpcs.default.vpcs.0.vswitch_ids.0
  internet_max_bandwidth_out = 50
}

