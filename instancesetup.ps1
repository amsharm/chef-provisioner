# This is a standalone Powershell script which leverages the AWS .NET API to provision instances and load balancer through AWS OpsWorks

# Load AWS SDK assemblies
Add-Type -path 'C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWS*.dll'

# The ID of the stack that I'm testing with. Eventually this will be programmatically set
$stackId = "224b49c1-3fc2-4e4d-8371-963c7a8c3ac5"

# Create the OpsWorks client 
$opsworksClient = New-Object Amazon.OpsWorks.AmazonOpsWorksClient([Amazon.RegionEndpoint]::USEast1)

# Create and customize the layer request object. Part of the customization for this is adding a recipe that installs the Octopus Deploy tentacle to the layer setup event
$layerReq = New-Object Amazon.OpsWorks.Model.CreateLayerRequest
$layerType = New-Object Amazon.OpsWorks.LayerType("Custom")
$layerRecipes = New-Object Amazon.OpsWorks.Model.Recipes
$configureRecipesList = New-Object System.Collections.Generic.List[System.String]
$configureRecipesList.Add("installoctopus::default")
$layerRecipes.Setup = $configureRecipesList
$layerReq.Name = "PerfAchievementLayer"
$layerReq.StackId = $stackId
$layerReq.Type = $layerType
$layerReq.Shortname = "perfach"
$layerReq.CustomRecipes = $layerRecipes
$createLayerResponse = $opsworksClient.CreateLayer($layerReq)
$layerId = $createLayerResponse.LayerId

# Create and customize the instance request object
$instanceReq = New-Object Amazon.OpsWorks.Model.CreateInstanceRequest
$instanceReq.StackId = $stackId 
$instanceReq.LayerIds = $layerId
$instanceReq.InstanceType="t2.micro"

# Create two instances and store their instance ids
$instanceReqResponse = $opsworksclient.CreateInstance($instanceReq)
$instanceId_1 = $instanceReqResponse.InstanceId
$instanceReqResponse = $opsworksclient.CreateInstance($instanceReq)
$instanceId_2 = $instanceReqResponse.InstanceId

# Start the instances
$startInstanceReq_1 = New-Object Amazon.OpsWorks.Model.StartInstanceRequest
$startInstanceReq_2 = New-Object Amazon.OpsWorks.Model.StartInstanceRequest
$startInstanceReq_1.InstanceId = $instanceId_1
$startInstanceReq_2.InstanceId = $instanceId_2
$opsworksClient.StartInstance($startInstanceReq_1)
$opsworksClient.StartInstance($startInstanceReq_2)

# Wait until instances are online. Reason for this is that we cannot attach the ELB until the instances are online
$instancesOnlineFlag = 0
$instanceIds = New-Object System.Collections.Generic.List[System.String]
$instanceIds.Add($instanceId_1)
$instanceIds.Add($instanceId_2)
$describeInstancesReq = New-Object Amazon.OpsWorks.Model.DescribeInstancesRequest
$describeInstancesReq.InstanceIds = $instanceIds
$sw = [system.diagnostics.stopwatch]::startNew()
while ($instancesOnlineFlag -eq 0){
    $instancesOnlineFlag = 1
    $describeInstancesResponse = $opsworksClient.DescribeInstances($describeInstancesReq)
    $instancesResponseList = $describeInstancesResponse.Instances
    foreach ($instance in $instancesResponseList){
        if($instance.Status -ne "online") {
            Write-Host "Instance status: "$instance.Status`n
            $instancesOnlineFlag = 0
            break
        }
    }
    if($instancesOnlineFlag -eq 1){
       break
    }
    else{
        Write-Host "The instances are currently in the process of starting up. Please wait... `nCurrent elapsed time: "
        Write-Host $sw.Elapsed `n `n
    }
    Start-Sleep -s 15
}

$sw.Stop()
# Create the ELB client
$elbClient = New-Object Amazon.ElasticLoadBalancing.AmazonElasticLoadBalancingClient([Amazon.RegionEndpoint]::USEast1)

# Create and customize the ELB request object
$elbReq = New-Object Amazon.ElasticLoadBalancing.Model.CreateLoadBalancerRequest
$listener = New-Object Amazon.ElasticLoadBalancing.Model.Listener("HTTP",80,80)
$elbReq.LoadBalancerName="testELB"
$elbReq.Listeners = $listener
$elbReq.Subnets = "subnet-0e8c5556"

# Create the ELB
$elbClient.CreateLoadBalancer($elbReq)

# Now, we will attach the instances to the ELB, but first we need to store the instance ids in the right format
$instanceList = New-Object System.Collections.Generic.List[Amazon.ElasticLoadBalancing.Model.Instance]
$instanceContainer_1 = New-Object Amazon.ElasticLoadBalancing.Model.Instance
$instanceContainer_2 = New-Object Amazon.ElasticLoadBalancing.Model.Instance
$describeInstancesResponse = $opsworksClient.DescribeInstances($describeInstancesReq)
$instancesResponseList = $describeInstancesResponse.Instances
$instanceContainer_1.InstanceId = $instancesResponseList.Item(0).Ec2InstanceId
$instanceContainer_2.InstanceId = $instancesResponseList.Item(1).Ec2InstanceId
$instanceList.Add($instanceContainer_1)
$instanceList.Add($instanceContainer_2)

# Create and customize the request object that is used to attach the instances to the elb
$registerInstancesReq = New-Object Amazon.ElasticLoadBalancing.Model.RegisterInstancesWithLoadBalancerRequest
$registerInstancesReq.Instances = $instanceList
$registerInstancesReq.LoadBalancerName = "testELB"

# Attach the instances to the ELB
$elbClient.RegisterInstancesWithLoadBalancer($registerInstancesReq)

# Create the DynamoDB client
$dynamoClient = New-Object Amazon.DynamoDBv2.AmazonDynamoDBClient([Amazon.RegionEndpoint]::USEast1)

# Create and customize the table request object
$tableReq = New-Object Amazon.DynamoDBv2.Model.CreateTableRequest
$tableReq.TableName = "PerformanceAchievement"

# Specify the attribute definitions for this table
$attributesList = New-Object System.Collections.Generic.List[Amazon.DynamoDBv2.Model.AttributeDefinition]
$stringAttributeType = New-Object Amazon.DynamoDBv2.ScalarAttributeType("S")
$careerLevelAttribute = New-Object Amazon.DynamoDBv2.Model.AttributeDefinition
$employeeNameAttribute = New-Object Amazon.DynamoDBv2.Model.AttributeDefinition
$careerLevelAttribute.AttributeName = "Career Level"
$careerLevelAttribute.AttributeType = $stringAttributeType
$employeeNameAttribute.AttributeName = "Employee Name"
$employeeNameAttribute.AttributeType = $stringAttributeType
$attributesList.Add($careerLevelAttribute)
$attributesList.Add($employeeNameAttribute)
$tableReq.AttributeDefinitions = $attributesList

# Specify the Key Schema list
$keySchemaList = New-Object System.Collections.Generic.List[Amazon.DynamoDBv2.Model.KeySchemaElement]
$hashKeyType = New-Object Amazon.DynamoDBv2.KeyType("HASH")
$rangeKeyType = New-Object Amazon.DynamoDBv2.KeyType("RANGE")
$careerLevelKeyElement = New-Object Amazon.DynamoDBv2.Model.KeySchemaElement
$employeeNameKeyElement = New-Object Amazon.DynamoDBv2.Model.KeySchemaElement
$careerLevelKeyElement.AttributeName = "Career Level"
$careerLevelKeyElement.KeyType = $hashKeyType
$employeeNameKeyElement.AttributeName = "Employee Name"
$employeeNameKeyElement.KeyType = $rangeKeyType
$keySchemaList.add($careerLevelKeyElement)
$keySchemaList.add($employeeNameKeyElement)
$tableReq.KeySchema = $keySchemaList

# Specify the provisioned throughput
$provisionedThroughput = New-Object Amazon.DynamoDBv2.Model.ProvisionedThroughput
$provisionedThroughput.ReadCapacityUnits = 20
$provisionedThroughput.WriteCapacityUnits = 50
$tableReq.ProvisionedThroughput = $provisionedThroughput

# Create the DynamoDB table
$dynamoClient.CreateTable($tableReq)
