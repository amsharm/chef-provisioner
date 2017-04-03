require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest", 
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

machine_options1 = {:bootstrap_options => {
                      :image_id => "ami-3d787d57", 
                      :instance_type => "t2.micro",
                      :subnet_id => "subnet-c7812d9f",
                      :key_name => "aman_key",
                      :security_group_ids => "sg-11082169",
                      :user_data => "<powershell>\nwinrm quickconfig -q\nwinrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"300\"}'\nwinrm set winrm/config '@{MaxTimeoutms=\"1800000\"}'\nwinrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'\nwinrm set winrm/config/service/auth '@{Basic=\"true\"}'\n\nnetsh advfirewall firewall add rule name=\"WinRM 5985\" protocol=TCP dir=in localport=5985 action=allow\nnetsh advfirewall firewall add rule name=\"WinRM 5986\" protocol=TCP dir=in localport=5986 action=allow\n\nnet stop winrm\nsc config winrm start=auto\nnet start winrm\ncscript C:\\Windows\\System32\\Scregedit.wsf /au 1\n</powershell>",
                      :placement => {
                        :availability_zone => "us-east-1a"  
                        }
                      },
                     :associate_public_ip_address => true,
                     :is_windows => true, 
                   }

machine_options2 = {:bootstrap_options => {
                      :image_id => "ami-3d787d57", 
                      :instance_type => "t2.micro",
                      :key_name => "aman_key",
                      :security_group_ids => "sg-11082169",
                      :user_data => "<powershell>\nwinrm quickconfig -q\nwinrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"300\"}'\nwinrm set winrm/config '@{MaxTimeoutms=\"1800000\"}'\nwinrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'\nwinrm set winrm/config/service/auth '@{Basic=\"true\"}'\n\nnetsh advfirewall firewall add rule name=\"WinRM 5985\" protocol=TCP dir=in localport=5985 action=allow\nnetsh advfirewall firewall add rule name=\"WinRM 5986\" protocol=TCP dir=in localport=5986 action=allow\n\nnet stop winrm\nsc config winrm start=auto\nnet start winrm\ncscript C:\\Windows\\System32\\Scregedit.wsf /au 1\n</powershell>",
                      :placement => {
                        :availability_zone => "us-east-1c"  
                        }
                      },
                     :associate_public_ip_address => true, 
                     :is_windows => true, 
                   }  

 execute "upload cookbooks" do
  command "knife cookbook upload installoctopus"
 end


machine_batch do
  machine 'aman_machine1' do
    machine_options machine_options1
    recipe 'installoctopus'
  end
  machine 'aman_machine2' do
    machine_options machine_options2
    recipe 'installoctopus'
  end
  end

load_balancer "aman-elb" do
    machines [ "aman_machine1", "aman_machine2" ]
    load_balancer_options :listeners => [{
        :port => 80,
        :protocol => :http,
        :instance_port => 80,
        :instance_protocol => :http,
    }]
end