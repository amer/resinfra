# Creds
## AZURE
variable resinfra_client_id {default = "fb38fb1d-4048-4da7-9cee-23dc07108cd3"}
variable resinfra_client_secret {default = "BPnnzLGYz5DQKu8Ep98p9kIdO5XiU_7ehE"}
variable resinfra_subscription_id {default= "4d436eda-8b35-4bb5-abb1-74906b539d05"}
variable resinfra_tenant_id {default = "e9988f08-489f-42ed-be81-334948e1a45e"}

## AWS
variable aws_access_key {default = ""}
variable aws_secret_key {default = ""}
variable aws_session_token {default = "FwoGZXIvYXdzENT//////////wEaDGL8MrPCeHNoU3FmrSLPAeCgObmqWP/UhBXC4tf7No3exesBeQg2oWRXejiZw6CuxTeveZxxWUrTFL4XteudDuF6cnXCLFoNWuldIudiCG+sdC49e8NhLYPcwgyt5+Ds7XpIpZEqOSoXRSZCWtDdbONAdJK3Bn2jkpYlitG6UKg8Sge9YNaMcYKKu2MRUbC1GQTlgKCAY+mkE075SCh2w2AVOwQVjuirE6iMKoAF3akakE+kzeys96vTJjSjCcSC8Ef/zWfXHATlnhy/c/mQnORP7PVB651MIQBEWYC1wijf2ML+BTIt4PJGdz/97YABIsxVH90MD+tIOIv19sDeQWsCt1ywHXGhTq1NPie6s5r6XvHq"}

## HETZNER
variable hetzner_token {default= "cHqj3oBZrRZF83yiEGL7RIVIHmtwoP0OI8gap4CemBWi6Y2Px2e4us34l97m4DkZ"}

# NETOWRK CONFIGS
variable hetzner_vpc_cidr {default="10.0.0.0/12"}
variable hetzner_subnet_cidr {default="10.0.1.0/24"}

variable azure_vpc_cidr {default = "10.1.0.0/16"}
variable azure_vm_subnet_cidr {default = "10.1.1.0/24"}
variable azure_gateway_subnet_cidr {default = "10.1.2.0/24"}

variable shared_key {default = "aksjdcsajhdcinsadicnsdauicnsughuscbhjsdbvszuaedgffzusgczugasdzvgsahjvdahcbhzsgdczgszdv"}
