# To list all the instances in a region along with their ID, Instance type, Private IP address, and their name in tabular format
* aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId, InstanceType, PrivateIpAddress, Tags[?Key==`Name`]|[0].Value]' --output table  
