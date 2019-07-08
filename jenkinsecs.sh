#!/bin/bash

aws ecs create-cluster --cluster-name NitishCluster

printf '#!/bin/bash\nECS_CLUSTER=NitishCluster" >> /etc/ecs/ecs.config ' > userdata.txt


ec2ID=`aws ec2 run-instances --image-id ami-0302f3ec240b9d23c --count 1 --instance-type t2.micro --key-name <name-of-ur-key> --iam-instance-profile Name="jenkins" --user-data file://userdata.txt --subnet-id subnet-be1e88e6 --security-group-ids sg-0d932b3e8a8f81e94
 --query 'Instances[].InstanceId' --output text`
sleep 3m 

tgarn=`aws elbv2 create-target-group --name Nitish-tg1 --protocol HTTP --port 8080 --vpc-id vpc-26c1dc42 --query 'TargetGroups[].TargetGroupArn' --output text`

aws elbv2 register-targets --target-group-arn ${tgarn} --targets Id=${ec2ID}


lbarn=`aws elbv2 create-load-balancer --name Nitish-alb --subnets subnet-be1e88e6 subnet-ec171288 subnet-f093cf86 --security-groups sg-0d932b3e8a8f81e94 --query 'LoadBalancers[].LoadBalancerArn' --output text`
aws elbv2 create-listener --load-balancer-arn ${lbarn} --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=${tgarn}


aws ecs register-task-definition --network-mode bridge --family nginx --volumes "[{\"name\": \"test\",\"host\": {\"sourcePath\": \"/var/log\"}}]"  --container-definitions "[{\"name\":\"test\",\"image\":\"nginx\",\"cpu\":256,\"memory\":256,\"essential\":true, \"portMappings\":[{\"hostPort\":80,\"containerPort\":80,\"protocol\":\"tcp\"}],\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"awslogs-nginx-ecs\",\"awslogs-region\":\"us-east-1\", \"awslogs-stream-prefix\":\"nginx\"}}, \"mountPoints\": [{\"sourceVolume\":\"test\",\"containerPath\":\"/var/log\",\"readOnly\":false}]}]"

aws ecs create-service --service-name Nitish-nginx --cluster NitishCluster --task-definition nginx --desired-count 1  --load-balancers "[{\"targetGroupArn\":\"${tgarn}\",  \"containerName\":\"test\", \"containerPort\":80}]" --role ecsServiceRole
