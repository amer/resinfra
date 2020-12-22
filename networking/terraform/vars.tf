# Creds
## AZURE
variable resinfra_client_id {default = ""}
variable resinfra_client_secret {default = ""}
variable resinfra_subscription_id {default= ""}
variable resinfra_tenant_id {default = ""}

## AWS
variable aws_access_key {default = ""}
variable aws_secret_key {default = ""}
variable aws_session_token {default = ""}

## HETZNER
variable hetzner_token {default= ""}

# NETOWRK CONFIGS
variable hetzner_vpc_cidr {default="10.0.0.0/12"}
variable hetzner_subnet_cidr {default="10.0.1.0/24"}

variable azure_vpc_cidr {default = "10.1.0.0/16"}
variable azure_vm_subnet_cidr {default = "10.1.1.0/24"}
variable azure_gateway_subnet_cidr {default = "10.1.2.0/24"}

variable shared_key {default = "aksjdcsajhdcinsadicnsdauicnsughuscbhjsdbvszuaedgffzusgczugasdzvgsahjvdahcbhzsgdczgszdv"}
