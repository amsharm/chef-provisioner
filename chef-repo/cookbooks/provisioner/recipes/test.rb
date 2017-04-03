require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest", 
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

machine_options1 = {:bootstrap_options => {
                      :image_id => "ami-3d787d57", #Windows Server 2012 R2
                      :instance_type => "t2.micro",
                      :availability_zone => "us-east-1a",
                      :subnet_id => "subnet-c7812d9f", #subnet should allow auto assigning of public IP
                      :key_name => "aman_key", #.pem file should be stored in \chef-repo\.chef\keys\
                      :security_group_ids => "sg-11082169",
                      :user_data => "<powershell>\nwinrm quickconfig -q\nwinrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"300\"}'\nwinrm set winrm/config '@{MaxTimeoutms=\"1800000\"}'\nwinrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'\nwinrm set winrm/config/service/auth '@{Basic=\"true\"}'\n\nnetsh advfirewall firewall add rule name=\"WinRM 5985\" protocol=TCP dir=in localport=5985 action=allow\nnetsh advfirewall firewall add rule name=\"WinRM 5986\" protocol=TCP dir=in localport=5986 action=allow\n\nnet stop winrm\nsc config winrm start=auto\nnet start winrm\ncscript C:\\Windows\\System32\\Scregedit.wsf /au 1\n</powershell>"
                      },
                     :associate_public_ip_address => true,
                   	 :is_windows => true #defaults to false
                   }

machine 'aman_test' do 
  machine_options machine_options1
  recipe 'installiis::default'  
end
