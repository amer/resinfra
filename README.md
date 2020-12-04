# Asynchronous Daily Stand-ups | [article](https://medium.com/@stevoscript/why-your-team-should-try-asynchronous-daily-stand-ups-87f1b809e5c8)

1. What did you do yesterday? (suggestion: the last time?)
1. What did you do today?
1. Is there anything blocking you from moving forward?

## 04.12.2020
### Julian
1. The last time I had the team meeting and also a meeting with hundertserver. 
2. Today I will work on the review comments for the standalone deployment script and start with the async planning process
3. My second story is blocked untill we have a first working prometheus deployment.

## 03.12.2020

### Tim
1. Yesterday I completed the work with hcloud, now able to deploy similar debian 
   machines among all providers. Worked with `cloud-init` to check for soultions 
   regarding the different username problem.
2. Today, I'll finish my work with `cloud-init`, update the documentation and 
   submit my pull request.
3. none

## 02.12.2020

### Johann
1. Yesterday, I tried and failed to setup a VPN connection between HCloud and AWS using StrongSWAN on the HCloud side.
2. I will be reading the StrongSWAN documentation to try and understand what's happening.
3. no blockers

### Jan
1. Yesterday, I looked into the different approaches to store the current state of the infrastructure and elaborated on that with Amar. I also talked to Nitho about what other storage requirements we have in order to be able to build the dashboards that we need. I also put some thoughts into how (or even if) we want to store logs.
2. Today, I want to move forward on getting a better understanding of the entire architecture together with the team.
3. I am still not entirely sure to what extend we need to run analytics on top of our monitoring solution and if our current design decisions could cope with such a requirement.

### Tim
1. Yesterday, I had a call with Julian and we fixed his ansible problem. Also I 
   created machines with the most recent debian image on aws and azure. 
2. Today, I'll continue with the most recent image for hcloud, and combine the 
   three into my branch. Also add documentation to it.
3. No blocker, but we could talk about using one playbook to ensure that 
   versions of specific software are the same. Depends on if we need that 
   granular control.
   
### Julian
1. Yesterday, I finished the standalone deployment tool.
2. Today, I had some meetings and we have to discuss some management topics.
3. My second story is blocked untill we have a first working prometheus deployment.

## 01.12.2020

### Johann
1. Yesterday, I clarified the scope of item #146 together with Julian, and decided on how to handle multi-tenancy in Azure / AWS.
2. Today, I will be setting up a VPN client + server on Hetzner to connect to AWS. 
3. no blockers

### Julian
1. Yesterday, I created a script to deploy vms on all our cloud providers and on a proxmox server
2. Today, I will try to finish the script and start with the sprint planning for the next sprint.
3. The aws ansible deployment is currenty not working correctly and i am not able to get the public ip after the deployment on some providers. For the next sprint planning i need some of the current progress and problems that may lead to new stories, but currently there is nearly no information on what is done and what are the problems encountered. 

### Jan
1. Yesterday, I started the research on the storage solutions. 
2. Today I want to get a better understanding of the requirements of that storage solution and its role in the tooling.

### Tim
1. Yesterday, I worked on creating an image with packer on aws. I further looked 
   into the topic and figured that it might be an overkill to create images for 
   all cloud providres, as we also have to pay e.g. for the storage of the 
   images. As story 
   [#87](https://app.clubhouse.io/thinkdeep/story/87/find-a-way-to-deploy-or-configure-virtual-machines-in-a-way-that-all-vms-on-the-different-providers-will-work-and-look-the) 
   only requires they work/look the same, using a debian 10 image among all 
   might suffice.
2. Today, I'll have a call with Julian to help him fix the problem he is having 
   with ansible. I'll also look into how to use the most recent debian image 
   automatically on aws and maybe other providers.
3. No blocker

## 30.11.2020

### Johann
1. Yesterday, I began writing the documentation for a multi-tenant network across Azure & AWS.
2. Today, I will try to setup such a network using a single VPN gateway on each side instead of one per tenant.
3. no blockers

### Julian
1. The last time i had a meeting with hundertserver.
2. Today, i will create a script that combine our current terraform configs, so that it can create VMs on different providers.
3. No hard blocks but it would be nice if i could include the resulsts from story 79 and 87 in my current task.

### Tim
1. Familiarized myself with `packer` a bit.
2. Today, I will work on creating an image with packer on `aws` and look into
   options of how to ensure that machines will behave the same among cloud
   providers. Specify options in document.

### Roland
1. I merged my terraform script for AWS in the already existing terraform script in order to accommodate the new functionality [PR 7](https://github.com/amer/resinfra/pull/7)
2. I familiarized myself with the possible solutions for a VPN connection between two or more different virtual machines on different cloud providers in order to integrate one of the approaches into the existing terraform script for AWS
3. I read some articles and documentation about network configurations and VPN solutions in AWS and Azure

## 27.11.2020

### Amer
1. The last two days I was busy at work. Sorry, I couldn't join the Scrum poker
2. Today, I'll follow up with the planned stories and pickup stories to work on.
3. No blockers.

### Julian

1. The last two days I was doing the async sprint planning and preparation
2. Today, I will have a meeting with hundertserver
3. Currently some research stroies are blocking me from planning further ahead

### Tim
1. We had our first asynchronous planning poker via slack and clubhouse.
2. Today, I'll look into the [PR 7](https://github.com/amer/resinfra/pull/7) and
   see how to best combine it with my previous work.
3. Not really blocking point, but as I want to work on
   [#87](https://app.clubhouse.io/thinkdeep/story/87/find-a-way-to-deploy-or-configure-virtual-machines-in-a-way-that-all-vms-on-the-different-providers-will-work-and-look-the)
   I need to familiarize myself with e.g. `packer` which I did not use
   previously.

### Roland
1. I familiarized myself with the new user stories and participated in the asynchronous sprint planning afterwards
2. I looked into how to integrate my terraform script with the already existing one [PR 7](https://github.com/amer/resinfra/pull/7)
3. I tested the newly integrated terraform script to ensure compatibility

### Jan
1. I looked and commented on the open PRs and finalized by reserach on the monitoring solutions.
2. Today, I want to get an understanding of what needs to be done for the following sprint.

## 25.11.2020
### Amer
1. On 25.11.2020, I finished [#73](https://app.clubhouse.io/thinkdeep/story/73/use-terraform-to-create-a-virtual-machine-on-azure-in-an-configured-vpc) and [#80](https://app.clubhouse.io/thinkdeep/story/80/use-terraform-to-create-a-vm-and-a-suitable-network-configuration-for-azure) and merged into `main`.
2. I'll not work today because of tech problems at work.
3. No blockers.

## 25.11.2020
### Julian
1. The last time, i solved change request
2. Today, I will plan some stories for the next week and have a look into a more asynchronous communication.
3. Nearly no work is done but no one came up with issues or questions. So i am not sure if they are done and simply not finished documenting or if they don't fulfill our submission policy. Because i don't know their experience and the results of the research task, I am not sure how to proceed with story creation.

### Amer
1. Yesterday,
	- Reviewed story [#82](https://app.clubhouse.io/thinkdeep/story/82/investigate-and-demonstrate-a-solution-for-monitoring-a-vm)
	- Read about virtual networking and service meshes.
2. Today, I'll work on [#73](https://app.clubhouse.io/thinkdeep/story/73/use-terraform-to-create-a-virtual-machine-on-azure-in-an-configured-vpc) and [#80](https://app.clubhouse.io/thinkdeep/story/80/use-terraform-to-create-a-vm-and-a-suitable-network-configuration-for-azure)
3. No blockers.

### Tim
1. Yesterday, I found a way to automatically run the ansible playbook once the
   machines/ssh are ready. Created the script and documentation.
2. Today, we'll have our weekly meeting. Also want to improve upon
   documentation.
 
## 24.11.2020
### Nitho
1. Yesterday I looked into how Consul handle multi-datacenter implementation
2. Jan mention an interesting idea about making the whole system event-driven (possibly based on Kafka). I will look into this today
3. Since Consul use gossip communication for its service discovery, it can be too chatty if there are a lot of events going on.

### Roland
1. I have read up on the topic of network configuration in AWS
2. I created a terraform script to deploy a fully configured vm in AWS with a VPC, a subnet, a public IP address, an internet gateway and security groups
3. I wrote a small piece of documentation for the terraform script


### Tim
1. Yesterday I created an `ansible playbook` that sets up an Nginx web server
   using docker containers.
2. Today, I'll work on automatically running the playbook once the machines/ssh
   are ready. Also I'll finish my documentation for both terraform and Ansible.

## 23.11.2020
### Johann
1. Yesterday, I did nothing.
2. Today, I'll work on [#120](https://app.clubhouse.io/thinkdeep/story/120/investigate-and-design-an-architecture-to-connect-the-vms-across-different-cloud-provider-aws-and-azure). Because I don't know all that much about internet routing, I need to spend a lot of time reading up on the basics.
3. Because I'm spending a lot of time learning, the item might not be completed this sprint.

### Julian
1. The last time, i created a terraform configuration to create VMs on Proxmox.
2. Today, i will try to resolve some change requests that i got from my team members.
3. Currently, i am done with my stories, but i have to take a look in the stories for the next weeks. Some stories may be evolving from currently not fulfilled stories, so i am not sure how to react to the delay.

## Nitho
1. On Saturday I started to look into various service registry implementation, but no concrete ideas yet.
2. Today I will look further into Consul, which was the main suggestion during the meeting.
3. Not really at the moment, since this is just an exploratory phase now.

### Roland
1. I have set up and initialized my AWS student account
2. I developed a basic terraform script which deploys a ubuntu vm to AWS EC2

### Tim
1. Yesterday I created a terraform script that deploys a VM
2. Today I'll look into `ansible` as an easy deployment tool to deploy an
   application as defined in
   [#77](https://app.clubhouse.io/thinkdeep/story/77/use-an-easy-deployment-tool-to-deploy-an-application-via-docker-on-the-vms)

### Jan
1. Yesterday, I finalized my Hetzner terraform script. I added the functionality to also deploy a floating ip as well as mounting a volume to the VM. 
2. Today, I want to take a look at the work from my teammates.

## 21.11.2020
### Julian
1. The last time, i did planing for the next sprint.
2. Today, I'will use terraform to create a VM on an Proxmox server.
3. Currently i am not aware anything blocking me.

### Roland
1. I have read the documentation of terraform in order to get a basic understanding of the tool

### Tim
1. Familiarized myself with `terraform` by reading documentation and setting it up
2. Today I'll try and setup an `aws ec2` machine using `terraform`
3. No blocking points thus far.

### Jan
1. Getting strated on working with terraform and hetzner. Looking into some old projets in order to find useful ressources. 
2. Today I want to have a first running version of my terraform script.

## 19.11.2020
### Amer
1. Yesterday, Setup the Github repository and Clubhouse account.
2. Today, I'll write the basic structure of the Github Wiki and some development guidelines (Conventional commits, Scrum).
3. No blockers.

## dd.mm.YYYY
### Amer | e.g. template
1. Yesterday, I did...
1. today, I'll do...
1. I can't do story8 until story4 and story9 are done, because... any idea what I can do?

