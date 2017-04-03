require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest", 
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

machine_options1 = {:bootstrap_options => {
                      :image_id => "ami-252db932", #Windows Server 2012 R2
                      :instance_type => "t2.micro",
                      :availability_zone => "us-east-1a",
                      :subnet_id => "subnet-a4a49afc", #subnet should allow auto assigning of public IP
   #                   :security_group_ids => "sg-3c9f3347"
                      }
                   }


machine 'aman_test_1' do
		machine_options machine_options1
end

