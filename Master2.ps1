# This script acts as an orchestrator, making calls to a Packer template and Chef recipes

# createAMI.json is a Packer template that accepts a number of parameters used to create a Windows AMI with chef client, IIS,
# and an Octopus tentacle all configured. The output of the Packer run is saved to a file, so that I can programmatically
# reference AMI id of the AMI just created
packer build C:\Users\aman.f.sharma\Packer\createAMI.json | Tee-Object -filepath C:\Users\aman.f.sharma\packerlog.log

# Getting the AMI id from the newly created AMI. I then surround the AMI id in a JSON object so that it's in the right format
# for a Chef attribute and save it to an attributes file 
$AmiID = ((Get-Content C:\Users\aman.f.sharma\packerlog.log)[-1]).Split(" ")[-1]
$jsonString = "{AmiID:'"+$AmiID+"'}"
$jsonObject = $jsonString | ConvertFrom-Json
$jsonObject | ConvertTo-Json -depth 999 | Out-File -Encoding ascii "C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\attributes.json"

# Run chef and pass in the newly created AMI
chef-client -z -j C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\attributes.json C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\recipes\test3.rb | Tee-Object -filepath C:\Users\aman.f.sharma\cheflog.log

# As a part of the chef run, an auto scaling group is created. The unique id or ARN of the scaling group is saved to a txt file 
# so that it can be passed in as a parameter on the second chef run below which is used to create a Cloudwatch alarm 
# linked to the newly created auto scaling group
$scalingGroupARN = Get-Content C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\scalinggroup.txt
$jsonString = "{ScalingGroupARN:'"+$scalingGroupARN+"'}"
$jsonObject = $jsonString | ConvertFrom-Json
$jsonObject | ConvertTo-Json -depth 999 | Out-File -Encoding ascii "C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\scalinggroup.json"
Start-Sleep -s 1500
chef-client -z -j C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\scalinggroup.json C:\Users\aman.f.sharma\chef-repo\cookbooks\provisioner\recipes\cloudwatch.rb 