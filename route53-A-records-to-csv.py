import boto3,csv

def lambda_handler(event, context):
    client = boto3.client('route53')
    response = client.list_resource_record_sets(HostedZoneId='ZXXXXXXXXXXXX123')

    dnsName = []
    hostName = []
    privateIp = []
    for i in response['ResourceRecordSets']:
    	dnsName.append(i['Name'])
    	privateIp.append(i['ResourceRecords'][0]['Value'])


    for j in dnsName:
    	hostName.append(j.split('.')[0])

    filename = "my-aws-hostname-record.csv"
    file = open('/tmp/'+ filename, 'w', newline ='')
    with file:
    	header = ['Hostname','DNS','Private IP']
    	writer = csv.DictWriter(file, fieldnames = header)
    	writer.writeheader()
    	for i in range(0,len(hostName)):
    		writer.writerow({'Hostname' : hostName[i],  
                         'DNS': dnsName[i],  
                         'Private IP': privateIp[i]})
    
    s3 = boto3.resource('s3')
    BUCKET = "test"

    s3.Bucket('gstn-pt-hostname-records').upload_file("/tmp/my-aws-hostname-record.csv", "my-aws-hostname-record.csv")
    
    return {'status': 'True', 'statusCode': 200, 'body': 'File Uploaded'}
