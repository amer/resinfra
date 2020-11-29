# Connecting VMs across different cloud providers, AWS and Azure, in a MT-compatible way

This is the report on item [#146](https://app.clubhouse.io/thinkdeep/story/146/investigate-and-design-an-architecture-to-connect-the-vms-across-different-cloud-providers-revisited). It is an extension of the [previous report](Azure-AWS-VPN.md). Again, we can use either a DIY VPN solution using open source tools (BIRD and Wireguard were mentioned during planning), or managed services offered by the cloud providers.

Multiple tenants can be isolated either using seperate VPCs for each tenant...

![](https://media.clubhouse.io/api/attachments/files/clubhouse-assets/5faee1ab-b9ba-4839-9191-1494224bf19b/5fbea150-8c65-4521-857c-106b59170757/Build%20a%20more%20resilient%20infrastructure%20by%20spanning%20clouds%20-%20New%20frame%20(2).jpg)

...or by using a single global VPC for all tenants and putting each tenant in their own subnet:

![](https://media.clubhouse.io/api/attachments/files/clubhouse-assets/5faee1ab-b9ba-4839-9191-1494224bf19b/5fbea151-4a65-4125-b046-47a2c361b793/Build%20a%20more%20resilient%20infrastructure%20by%20spanning%20clouds%20-%20New%20frame%20(1).jpg)

## Per-Tenant VPC

For this approach, the steps described in the [previous report](Azure-AWS-VPN.md) would need to be repeated for each tenant. Due to the near-total separation between tenants, we would not introduce any conflicts or additional security issues. It is also likely to be the simplest solution.

### Cost Estimation

Three services costing actual money would be replicated for each tenant: The VPN gateways, and the public IP address for Azure. Depending on the amount of inter-cloud traffic, this might become neglible compared to the cost of outbound traffic.

#### On Azure Germany West Central

| Service                | Sizing   | Price      |
| ---------------------- | -------- | ---------- |
| [VPN Gateway][1]       | 100 Mb/s | 0,04 \$/h  |
| [Public IP Address][2] | Static   | 0,0036 $/h |
| [Outbound Traffic][1]  | any      | 0,035 $/GB |

#### On AWS Europe (Frankfurt)

| Service               | Sizing | Price     |
| --------------------- | ------ | --------- |
| [VPN][3]              | any    | 0,05 $/h  |
| [Outbound Traffic][4] | <10 TB | 0,09 $/GB |

## Global VPC with subnet-level tenant separation

We could use one common VPN gateway each on Azure and AWS. Would we then be able to use static route tables and security groups to fully separate tenants at the network level, or would we need more feature-rich soultions such as BIRD + Wireguard?

## DIY?


[1]: https://azure.microsoft.com/en-us/pricing/details/vpn-gateway/
[2]: https://azure.microsoft.com/en-us/pricing/details/ip-addresses/
[3]: https://aws.amazon.com/de/vpn/pricing/
[4]: https://aws.amazon.com/de/ec2/pricing/on-demand/