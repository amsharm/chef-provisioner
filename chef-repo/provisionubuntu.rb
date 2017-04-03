require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest", 
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

machine_options1 = {:bootstrap_options => {
                      :image_id => "ami-fce3c696", 
                      :instance_type => "t2.micro",
                      :key_name => "aman_key",
                      :security_group_ids => "sg-11082169",
                      :placement => {
                      	:availability_zone => "us-east-1a"	
                      	}
                      },
                      :ssh_username => 'ubuntu'
                   }

machine_options2 = {:bootstrap_options => {
                      :image_id => "ami-fce3c696", 
                      :instance_type => "t2.micro",
                      :key_name => "aman_key",
                      :security_group_ids => "sg-11082169",
                      :placement => {
                      	:availability_zone => "us-east-1c"	
                      	}
                      },
                      :ssh_username => 'ubuntu'                      
                   }	

 # execute "upload cookbooks" do
 # 	command "knife cookbook upload installoctopus"
 # end

machine_batch do
	machine 'aman_machine1' do
		machine_options machine_options1
	#	recipe 'installoctopus'
	end
	machine 'aman_machine2' do
		machine_options machine_options2
	#	recipe 'installoctopus'
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