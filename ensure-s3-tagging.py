import boto3
client = boto3.client('s3')

s3_bucket = client.list_buckets()
s3list = []
defaulterBuckets = []
for i in range(len(s3_bucket['Buckets'])):
    s3list.append(s3_bucket['Buckets'][i]['Name'])

# Set of necessary tags 
myTags=set(['Project','Environment'])

try:
    for buckets in s3list:
        response = client.get_bucket_tagging(Bucket=buckets)
        tagset = response['TagSet']
        count = 0
        for tag in tagset:
            if(tag['Key'] in myTags):
                count += 1
            else:
                continue
        if(count != 2):
            defaulterBuckets.append(buckets)
except:
    print(buckets + "does not have any tags!")

################ SNS ################
sns = boto3.client('sns')
# Publish a simple message to the specified SNS topic
response = sns.publish(    
    TopicArn = 'arn:aws:sns:us-west-2:123456789:MyTopic',
    Message="Desired tag-key don't exist on these buckets : " + str(defaulterBuckets),    
)
# Print out the response
print(response)
