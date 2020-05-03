import boto3    
## This will replace the existing security groups with new security groups.
ec2client = boto3.client('ec2')
response = ec2client.describe_instances(
	Filters=[{
		'Name':'tag:Service',
		'Values':['cache']
	}])
instanceList = []
for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
        instanceList.append(instance["InstanceId"])

print("Mentioned SGs will be attached to "+ str(len(instanceList)) +" instances, as below!")
print(instanceList)

for i in instanceList:
	ec2client.modify_instance_attribute(
		InstanceId=i,
		Groups=['sg-xxxxxxxxxx213','sg-xxxxxxxxxx321','sg-sg-xxxxxxxxxx123']
		)
