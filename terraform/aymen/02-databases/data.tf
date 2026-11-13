# Reads the outputs (vpc id, subnet ids, security group ids) from the
# networking module's state file, so we don't have to copy IDs by hand.
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "cloud-design-tfstate-008041477168"
    key    = "aymen/01-networking/terraform.tfstate"
    region = "eu-north-1"
  }
}

locals {
  private_subnet_ids   = data.terraform_remote_state.networking.outputs.private_subnet_ids
  db_security_group_id = data.terraform_remote_state.networking.outputs.db_security_group_id
}
