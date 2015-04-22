# Takehome Assignment
The assignment was to setup a load balanced deployment of the Picky server on AWS. For this assignment I used a classic two-tier architecture, where the picky servers (second tier) sit behind a load balancer (first tier) for scaling and high availability.

## Common
### Orchestration
For automatic orchestration of this deployment, I utilized HashiCorp's Terraform tool to define the various AWS components in various files ending in ".tf". Terraform allows you to easily reason about infrastructure changes by showing the proposed changes to the deployment before you execute them. It also makes AWS configuration and various service dependencies a piece of cake, especially setting up a VPC, something that involves quite a few steps.
### Configuration Management
For this simple example, I used Ansible. Ansible's simple SSH-based agentless operation reduces single points of failure by eliminating a centralized server, and keeps things simple when building playbooks and roles. For a deployment that will eventually need to scale to hundreds of nodes or more, Ansible might be a bad fit due to the slow SSH connection setup time. SaltStack, Chef, and Puppet might be better suited for such a deployment, as they offer more scalable architectures, especially SaltStack.
### Networking
For networking I defined a VPC with a single internal subnet that uses an internet gateway for access to the internet. The Picky servers run a locked-down security group which only allows access to the Picky API and SSH from the local network. A bastion server allows for secure access to the private network via SSH's ProxyCommand feature, which can be seen in `ssh.config.template`. Ansible is configured to use this bastion server for access to the network which allows for seamless secure connections without the overhead or SPOF of a VPN server such as OpenVPN. For larger deployments, something more robust may be desired.
## Load Balancer
For this exercise I decided to use Amazon's ELB service for the load balancing, as it integrates cleanly into the AWS ecosystem, especially with Route 53's DNS hosting. The primary ELB, along with its rules and healthchecks, are defined using Terraform, and depends on the Picky instances, which Terraform builds and runs before assigning the instance IDs to the ELB. For more configurability, HAProxy could be used, but for this simple project it's hard to beat ELB.
## Picky Servers
### Ruby
The Picky servers run the version of Ruby available in the CentOS 7 repository, which is Ruby 2.0.0 with some patches. This is not ideal because the distro maintainers usually have to compile with a lot of extra flags that can lead to performance issues, in addition to Ruby 2.0.0 having many known issues that have been solved in 2.2.2. I used CentOS Ruby because it was easy to install, and is easy to update in case of security issues. In hindsight, I should have probably written my Ansible script to build an AMI, and I could have compiled Ruby from source with whatever flags I desired.
### Application Server
I ran into some odd issues with Unicorn interacting badly with Ruby 2.0.0, so I decided to go with Puma instead. Puma is in my opinion the latest and greatest application server, and works great across Ruby Platforms, especially on JRuby. I also prefer the overall experience of Puma over Unicorn, and feel that Puma will eventually supplant Unicorn's position in the market. I configured Puma to run in cluster mode using a simple systemd service. I also configured the systemd service to send all output to syslog for easier management.

## Extra Steps
### Log Monitoring
For log aggregation and monitoring, I configured rsyslogd to LogEntries, a centralized logging service. I chose LogEntries because of its ability to receive logs from syslog, which removes the need for a bulky agent running on each server. LogEntries is a pretty flexible service, and can accomplish most of the goals of typical log aggregation systems fairly simply. It also has a component which consumes AWS service logs via S3, so you could use this to consume the logs from ELB, EC2, etc and have them all in the same place.
### Traffic Monitoring
I did not have time to implement true traffic monitoring, but some simple functions could be accomplished from the LogEntries system alone. If I had more time, I would have probably setup a collectd install, or possibly even a InfluxDB install with Grafana for a front-end.
### Availability Monitoring
I didn't set this up either, but I would use CloudWatch combined with PagerDuty to handle basic monitoring of things. Unfortunately, Terraform doesn't have support for CloudWatch yet, but I'm sure it is coming soon. I also like to setup a non-AWS system like Pingdom for a backup, which also integrates with PagerDuty.

## Follow Up Questions
### How would we deploy new code?
Update the index, code, etc in roles/picky/files/picky/takehome, then run Ansible. For a Rails app or something else a bit more complicated than Picky, I would have the Ansible playbook pull the newest code from a Git repository set from an Ansible variable. If I were using AMIs, I would simply do this process, update the AMI, then edit the Terraform script to use the new AMI.
### How would we add another instance to the cluster?
Terraform makes this incredibly simple, just change the count of "aws_instance.picky", and run Ansible. If using an AMI, you probably wouldn't even need to run Ansible.
### How would we keep these instances updated for new security releases?
For OS updates, Ansible can easily be used to update all servers at once from the command line. You could also probably add it to the common role, and just run the main site.yml playbook with the "common" tag.
### Are there any security concerns you would implement for this type of a setup? If so, at
a high level how do you recommend we address them?
* TLS is not used for the syslog forwarding, so that needs to be fixed.
* TLS is not used to access the load balancer, which could be insecure depending on the search results
* There is no authentication/authorization to the Picky server. This could easily be handled by a frontend server like nginx, or  be added to the Ruby code as a rack middleware.
* The instances have public IP addresses assigned because I was having issues with connectivity without assigning them. This is obviously not ideal, and I'd like to fix this properly. The security groups for the picky instances is locked down to disallow public access.
## Do you have any suggestions or recommendations for this environment?
I've made quite a few above. The biggest one is converting to an AMI-based setup. I'd like to properly add traffic and availability monitoring, as well as fixing the security issues above. Also, Ansible runs really slowly and copies the server files over each time which would be fixed by separating the code from the index data, and using git/rsync to keep things up to date.
