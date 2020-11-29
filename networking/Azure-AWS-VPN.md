# Connecting VMs across different cloud providers, AWS and Azure

This is the report on item [#120](https://app.clubhouse.io/thinkdeep/story/120/investigate-and-design-an-architecture-to-connect-the-vms-across-different-cloud-provider-aws-and-azure). There are two basic methods of achieving our goal: A DIY VPN solution using open source tools (BIRD and Wireguard were mentioned during planning), or managed services offered by the cloud providers.

_TL;DR_: We should use the managed VPN services offered by Azure / AWS.

## DIY

### BIRD Internet Routing Daemon

BIRD is a daemon for dynamic internet routing. [Source](https://bird.network.cz/?get_doc&v=16&f=bird-1.html)

The scope of this story was to have one subnet per cloud, as shown in the [initial graphic](https://media.clubhouse.io/api/attachments/files/clubhouse-assets/5faee1ab-b9ba-4839-9191-1494224bf19b/5fb816ac-5391-4385-9d2f-3690b66cb47f/Build%20a%20more%20resilient%20infrastructure%20by%20spanning%20clouds%20-%20New%20frame.jpg). Therefore, we need no dynamic routing to connect the networks. A static route table will work just fine for now.

### Wireguard

Wireguard is a VPN. We could install it on one VM each on Azure / AWS, open a tunnel between them and route all traffic through it. However, if we can achieve the same results using a managed solution from the cloud provider, that would be preferable.

## Managed Services

### VPC Peering

Refers to either

- peering two VPCs, which is only applicable within one cloud provider's infrastructure, or
- private peering between a VPC and onprem (or something like that). Azure calls this ExpressRoute:

![ExpressRoute Overview](https://docs.microsoft.com/en-us/azure/expressroute/media/expressroute-introduction/expressroute-connection-overview.png)

I believe neither fits our use case, but it might be relevant later when we add a proxmox server to our network. For more details, see also the description of VPC at [GCP](https://cloud.google.com/vpc/docs/vpc-peering) or [AWS](https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html).

#### Cost Estimation

_Todo (or maybe not todo?)_

### Classic VPN

There are [instructions](https://www.hackernoon.com/how-to-connect-between-azure-and-aws-with-managed-services-4b03ec334e8a) on how to connect an Azure Virtual Network with an AWS VPC through the providers' managed VPN services. The approach consists of creating two gateways on each side, configuring a VPN (IPSec) connection, and editing the static route tables to point to the VPN gateway.

I followed the steps and verified that it works as described. Some parts of the UI have changed, but overall, the guide is still up-to-date. To verify the setup is functional, I tested the connection performance (AWS ap-south (Mumbai) ↔ Azure North Europe (Ireland)):

```txt
[ec2-user@ip-172-31-46-3 ~]$ iperf3 --client 10.0.0.4 -p 80
Connecting to host 10.0.0.4, port 80
[  4] local 172.31.46.3 port 41610 connected to 10.0.0.4 port 80
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec  2.43 MBytes  20.4 Mbits/sec    0    590 KBytes
[  4]   1.00-2.00   sec  6.60 MBytes  55.4 Mbits/sec  343    849 KBytes
[  4]   2.00-3.00   sec  5.99 MBytes  50.2 Mbits/sec    0    912 KBytes
[  4]   3.00-4.00   sec  6.42 MBytes  53.8 Mbits/sec    0    961 KBytes
[  4]   4.00-5.00   sec  6.66 MBytes  55.9 Mbits/sec    0    994 KBytes
[  4]   5.00-6.00   sec  6.85 MBytes  57.5 Mbits/sec    0   1016 KBytes
[  4]   6.00-7.00   sec  7.16 MBytes  60.0 Mbits/sec    0   1.00 MBytes
[  4]   7.00-8.00   sec  7.16 MBytes  60.0 Mbits/sec    0   1.01 MBytes
[  4]   8.00-9.00   sec  7.34 MBytes  61.6 Mbits/sec    0   1.01 MBytes
[  4]   9.00-10.00  sec  7.22 MBytes  60.6 Mbits/sec    0   1.01 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-10.00  sec  63.8 MBytes  53.5 Mbits/sec  343             sender
[  4]   0.00-10.00  sec  61.0 MBytes  51.2 Mbits/sec                  receiver

iperf Done.
```

The approach works, and I expect us to be able to automate it well. Manually transferring the PSK for IKEv1 is pretty cumbersome. We should try to find out if there is an easier way to connect the VPN.

#### Cost Estimation

##### On Azure Germany West Central

| Service                | Sizing  | Price                           |
| ---------------------- | ------- | ------------------------------- |
| [VPN Gateway][1]       | 100Mb/s | 0,04 \$/h + 0,035 $/GB outbound |
| [Public IP Address][2] | Static  | 0,003 €/h                       |

Local Gateway and VPN services appear to be free.

##### On AWS Europe (Frankfurt)

| Service               | Sizing | Price     |
| --------------------- | ------ | --------- |
| [VPN][3]              | any    | 0,05 $/h  |
| [Outbound Traffic][4] | <10TB  | 0,09 $/GB |

Gateways appear to be free.

## Open Questions

In no particular order:

- What will be our peak bandwith & traffic requirements?
  - Can we get a closer estimate of the cost in production, compared to deploying everything to one AZ?
- Which data centers should we choose to optimize latency and / or throughput?
  - How do they compare vs. an un-tunneled connection?
- Amazon recommends using two tunnels in parallel for redundancy. They even send you a nice e-mail about its benefits if you use only one tunnel. How can we configure this on the Azure side?
- For the VPN service, [Azure guarantees 99,9 or 99,95% availability](https://azure.microsoft.com/en-us/support/legal/sla/vpn-gateway/v1_4/), [AWS guarantees 99,95%](https://aws.amazon.com/de/vpn/site-to-site-vpn-sla/). What are the implications on the SLA we can offer?
- IKEv1 with a PSK is pretty cumbersome. How can we automate the key exchange? Can we use certificates?
- How to automate all this?

[1]: https://azure.microsoft.com/en-us/pricing/details/vpn-gateway/
[2]: https://azure.microsoft.com/en-us/pricing/details/ip-addresses/
[3]: https://aws.amazon.com/de/vpn/pricing/
[4]: https://aws.amazon.com/de/ec2/pricing/on-demand/
