import boto3
import json

def lambda_handler(event, context):

    ### Get a list of instances which are in Pending state
    client = boto3.client('ec2', region_name='ap-south-1')
    response = client.describe_instances(Filters=[{'Name' : 'instance-state-name','Values' : ['pending']}])
    
    ec2list = []
    events_dict = {}

    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            ec2list.append(instance["InstanceId"])

    ### Getting IAM user information who've launched the instance
    ct_conn = boto3.client(service_name='cloudtrail',region_name='ap-south-1')
    
    for i in ec2list:
        events_dict = ct_conn.lookup_events(LookupAttributes=[{'AttributeKey':'ResourceName', 'AttributeValue':i}])
    
    json_file = {}
    for data in events_dict['Events']:
        json_file.update(json.loads(data['CloudTrailEvent']))
    print(json_file)
    username = json_file['userIdentity']['userName']
    
    ### Extracting the value of tag:key role on IAM user
    iam = boto3.client('iam')
    iamTags = iam.list_user_tags(UserName=username)
    role = iamTags["Tags"][0]["Value"]

    ### Tagging EC2 Instances with IAM user tags
    for id in ec2list:
        print("This instance will be tagged : ", id)
        tagged_instances = client.create_tags(Resources=[id],Tags=[{'Key':'Role','Value':role},{'Key':'Project','Value':'MyProject'},{'Key':'Environment','Value':'dev'},{'Key':'Owner','Value':username}])
