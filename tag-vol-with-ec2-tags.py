import boto3


COPYABLE = ["Name"]

print('Processing EC2 Instances')

instances = boto3.resource('ec2').instances.all()
for instance in instances:
    tags = [t for t in instance.tags or [] if t['Key'] in COPYABLE]
    if not tags:
        continue

# Tag the EBS Volumes
for vol in instance.volumes.all():
    print('Updating tags for {}'.format(vol.id))
    vol.create_tags(Tags=tags)
