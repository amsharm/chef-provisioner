# See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "aman"
client_key               "C:/Users/aman.f.sharma/chef-repo/.chef/amanKey.pem"
chef_server_url          "https://VA105650.ds.dev.accenture.com/organizations/organization"
cookbook_path            ["C:/Users/aman.f.sharma/chef-repo/cookbooks"]
chef_provisioning({:image_max_wait_time => 600, :machine_max_wait_time => 600})