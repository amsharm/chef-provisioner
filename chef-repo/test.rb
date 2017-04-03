require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest",
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]
machine_options = { :bootstrap_options => {
                      :image_id => "ami-fce3c696", #Ubuntu
                      :instance_type => "t2.micro",
                      :key_name => "amantest"
                    },
   #                 :transport_address_location => :private_ip, 
    #                :timeout => 1800,
     #               :ssh_username => 'ubuntu'
                  }

machine "test-machine" do
	machine_options machine_options
end