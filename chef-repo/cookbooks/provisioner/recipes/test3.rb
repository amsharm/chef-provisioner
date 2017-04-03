require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest", 
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

aws_launch_configuration 'launch-config' do
    image node['AmiID']
    instance_type 't2.micro'
    options security_groups: 'sg-3c9f3347', key_pair: 'test_key_pair'
end

load_balancer "testelb" do
    machines([])
    load_balancer_options(
      {
        :availability_zones=>["us-east-1a", "us-east-1c"], 
        :listeners=>[{
          :instance_port=>80, 
          :protocol=>"HTTP", 
          :instance_protocol=>"HTTP", 
          :port=>80
          }],
        :health_check=> {
          :healthy_threshold=>2,
          :unhealthy_threshold=>2,
          :interval=>5,
          :timeout=>2,
          :target=>"HTTP:80/index.htm"
          }
      })
end

scaling_group =
  aws_auto_scaling_group 'my-auto-scaling-group' do
    desired_capacity 2
    min_size 1
    max_size 3
    load_balancers ["testelb"]
    availability_zones ['us-east-1a','us-east-1c']
    launch_configuration 'launch-config'
    scaling_policies({
      'scaleup-policy' => {
        :adjustment_type=> 'ChangeInCapacity',
        :scaling_adjustment=> 1,
        :cooldown=> 60
      },
      'scaledown-policy' => {
        :adjustment_type=> 'ChangeInCapacity',
        :scaling_adjustment=> -1,
        :cooldown=> 60
      }
      })
  end

ruby_block 'write-to-file' do
  block do
    file = File.open('C:/Users/aman.f.sharma/chef-repo/cookbooks/provisioner/scalinggroup.txt', 'w')
    file.write(scaling_group.aws_object.scaling_policies['scaleup-policy'].arn )
  end
end

aws_cloudwatch_alarm 'fake-alert' do
  namespace 'AWS/EC2'
  metric_name 'CPUUtilization'
  comparison_operator 'GreaterThanThreshold'
  evaluation_periods 10
  period 60
  statistic 'Average'
  threshold 99
end
