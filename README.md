# chef-provisioner

The purpose of this project is to use Chef Provisioning to provision AWS resources. It begins with a Packer template which creates a Windows AMI with chef-client, IIS, and an Octopus tentacle configured. It then passes this AMI as a parameter to a Chef Provisioning recipe which creates an auto scaling group, load balancer, and cloudwatch alarm in Accenture's sandbox environment. 
The cloudwatch alarm links with the auto scaling group and scales when the CPU utilization reaches a certain threshold. I wrote a Powershell script
which would simulate traffic to the instances just created. All of this is orchestrated by the powershell script Master2.ps1.
