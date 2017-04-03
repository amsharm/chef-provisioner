require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

with_driver 'aws::us-east-1'
with_chef_server "https://api.chef.io/organizations/amantest", 
  :client_name => Chef::Config[:node_name],
  :signing_key_filename => Chef::Config[:client_key]

aws_cloudwatch_alarm 'real-alert' do
  namespace 'AWS/EC2'
  metric_name 'CPUUtilization'
  comparison_operator 'GreaterThanThreshold'
  evaluation_periods 3
  period 60
  statistic 'Average'
  threshold 1
  alarm_actions [node['ScalingGroupARN']]
end