#!/bin/bash
now=$(date +"%H")
region="ap-south-1"
stop() {
	echo "Termination tasks of cluster $Project-$env-drupal-cluster"
	services=$(aws ecs list-services \
		--cluster $Project-$env-drupal-cluster \
    	--query serviceArns \
    	--output text \
    	--region $region)
	for service in $services
    do
        echo "Terminating tasks of service $service"
            aws ecs update-service \
                --cluster $Project-$env-drupal-cluster \
                --service $service \
                --region $region \
                --desired-count 0 
            
            runningtasks=$(aws ecs describe-services \
                --service  $service \
                --cluster $Project-$env-drupal-cluster \
                --query services[*].runningCount \
                --region $region \
                --output text)
            echo "Waiting for tasks to be terminiated"
            while [ $runningtasks -ne 0 ]
            do
                sleep 15
                runningtasks=$(aws ecs describe-services \
                    --service $service \
                    --cluster $Project-$env-drupal-cluster \
                    --query services[*].runningCount \
                    --region $region \
                    --output text)
                continue
            done
            echo "There are no more running tasks of service $service"
    done

    echo "Termination tasks of cluster $Project-$env-report-dc-cluster"
    services=$(aws ecs list-services \
		--cluster $Project-$env-report-dc-cluster \
    	--query serviceArns \
    	--output text \
    	--region $region)
    for service in $services
    do
        echo "Terminating tasks of service $service"
            aws ecs update-service \
                --cluster $Project-$env-report-dc-cluster \
                --service $service \
                --region $region \
                --desired-count 0 
            
            runningtasks=$(aws ecs describe-services \
                --service  $service \
                --cluster $Project-$env-report-dc-cluster \
                --query services[*].runningCount \
                --region $region \
                --output text)
            echo "Waiting for tasks to be terminiated"
            while [ $runningtasks -ne 0 ]
            do
                sleep 15
                runningtasks=$(aws ecs describe-services \
                    --service $service \
                    --cluster $Project-$env-report-dc-cluster \
                    --query services[*].runningCount \
                    --region $region \
                    --output text)
                continue
            done
            echo "There are no more running tasks of service $service"
    done

    echo "Terminating ECS Instances of ASG EC2ContainerService-$Project-$env-report-dc-cluster-EcsInstanceAsg-15CGSPHZCX9TN"
        
        aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name EC2ContainerService-$Project-$env-report-dc-cluster-EcsInstanceAsg-15CGSPHZCX9TN \
            --region $region \
            --min-size 0 \
            --desired-capacity 0 

        instanceid=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names EC2ContainerService-$Project-$env-report-dc-cluster-EcsInstanceAsg-15CGSPHZCX9TN \
            --query AutoScalingGroups[*].Instances[0].InstanceId \
            --region $region \
            --output text)
        
        echo "Waiting for 60 seconds for EC2 instance to be terminated"
        sleep 60

        aws ec2 wait instance-terminated --instance-ids $instanceid 
        if [ $? -eq 0 ]
        then
            echo "ECS Instance terminated successfully"
        else
            echo "Error while terminating ECS instance"
            exit 1
        fi


    echo "Terminating ECS Instances of ASG EC2ContainerService-$Project-$env-drupal-cluster-EcsInstanceAsg-VPY02QNC7NS5"
        
        aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name EC2ContainerService-$Project-$env-drupal-cluster-EcsInstanceAsg-VPY02QNC7NS5 \
            --region $region \
            --min-size 0 \
            --desired-capacity 0 

        instanceid=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names EC2ContainerService-$Project-$env-drupal-cluster-EcsInstanceAsg-VPY02QNC7NS5 \
            --query AutoScalingGroups[*].Instances[0].InstanceId \
            --region $region \
            --output text)
        
        echo "Waiting for 60 seconds for EC2 instance to be terminated"
        sleep 60

        aws ec2 wait instance-terminated --instance-ids $instanceid 
        if [ $? -eq 0 ]
        then
            echo "ECS Instance terminated successfully"
        else
            echo "Error while terminating ECS instance"
            exit 1
        fi

    echo "Stopping mongo and mysql instances"
	instance_ids=$(aws ec2 describe-instances \
		--filters "Name=tag:Stack,Values=hybrid, Name=instance-state-code,Values=16" \
		--query Reservations[*].Instances[*].InstanceId \
		--region $region \
		--output text
	for instance in $instance_ids
    do
        aws ec2 stop-instances \
            --instance-ids $instance \
            --region $region \
        && aws ec2 wait instance-stopped \
            --instance-ids $instance \
            --region $region

        if [ $? -eq 0 ]
        then
            echo "Instance $instance stopped successfully"
        else
            echo "Error while stopping instance $instance"
            exit 1
        fi
    done
}

start() {
	echo "Starting mongo and mysql instances"
	instance_ids=$(aws ec2 describe-instances \
		--filters "Name=tag:Stack,Values=hybrid, Name=instance-state-code,Values=80" \
		--query Reservations[*].Instances[*].InstanceId \
		--region $region \
		--output text
	for instance in $instance_ids
    do
        aws ec2 start-instances \
            --instance-ids $instance \
            --region $region \
        && aws ec2 wait instance-running \
            --instance-ids $instance \
            --region $region

        if [ $? -eq 0 ]
        then
            echo "Instance $instance started successfully"
        else
            echo "Error while starting instance $instance"
            exit 1
        fi
    done

    echo "Launching an ECS Instance through ASG EC2ContainerService-$Project-$env-drupal-cluster-EcsInstanceAsg-VPY02QNC7NS5"
    aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name EC2ContainerService-$Project-$env-drupal-cluster-EcsInstanceAsg-VPY02QNC7NS5 \
        --region $region \
        --min-size 1 \
        --desired-capacity 1 
    
    echo "Waiting for 60 seconds for EC2 instance to be available"
    sleep 60

    instanceid=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names EC2ContainerService-$Project-$env-drupal-cluster-EcsInstanceAsg-VPY02QNC7NS5 \
        --query AutoScalingGroups[*].Instances[0].InstanceId \
        --region $region \
        --output text)

    aws ec2 wait instance-running --instance-ids $instanceid 
    if [ $? -eq 0 ]
    then
        echo "ECS Instance started successfully"
    else
        echo "Error while starting ECS instance"
        exit 1
    fi

    echo "Launching an ECS Instance through ASG EC2ContainerService-$Project-$env-report-dc-cluster-EcsInstanceAsg-15CGSPHZCX9TN"
    aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name EC2ContainerService-$Project-$env-report-dc-cluster-EcsInstanceAsg-15CGSPHZCX9TN \
        --region $region \
        --min-size 1 \
        --desired-capacity 1 
    
    echo "Waiting for 60 seconds for EC2 instance to be available"
    sleep 60

    instanceid=$(aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names EC2ContainerService-$Project-$env-report-dc-cluster-EcsInstanceAsg-15CGSPHZCX9TN \
        --query AutoScalingGroups[*].Instances[0].InstanceId \
        --region $region \
        --output text)

    aws ec2 wait instance-running --instance-ids $instanceid 
    if [ $? -eq 0 ]
    then
        echo "ECS Instance started successfully"
    else
        echo "Error while starting ECS instance"
        exit 1
    fi

    echo "Waiting for instance to be placed in ecs cluster $Project-$env-drupal-cluster"
    registeredinstance=$(aws ecs describe-clusters \
        --cluster $Project-$env-drupal-cluster \
        --query clusters[*].registeredContainerInstancesCount \
        --region $region \
        --output text)
    while [ $registeredinstance == 0 ]
    do
        sleep 15
        registeredinstance=$(aws ecs describe-clusters \
        --cluster $Project-$env-drupal-cluster \
        --query clusters[*].registeredContainerInstancesCount \
        --region $region \
        --output text)
        continue
    done

    services=$(aws ecs list-services \
		--cluster $Project-$env-drupal-cluster \
    	--query serviceArns \
    	--output text \
    	--region $region)
	for service in $services
    do
        echo "Running tasks and waiting for ecs service $service to be stable"
            aws ecs update-service \
                --cluster $Project-$env-drupal-cluster \
                --service $service \
                --region $region \
                --desired-count 1 \
             && aws ecs wait services-stable \
        		--service $service  \
        		--cluster $Project-$env-drupal-cluster \
        		--region $region 
    	if [ $? -eq 0 ]
    	then
        	echo "Tasks of service $service are up and running"
    	else
        	echo "Error in deployment"
        	exit 1
    	fi
    done

    echo "Waiting for instance to be placed in ecs cluster $Project-$env-report-dc-cluster"
    registeredinstance=$(aws ecs describe-clusters \
        --cluster $Project-$env-report-dc-cluster \
        --query clusters[*].registeredContainerInstancesCount \
        --region $region \
        --output text)
    while [ $registeredinstance == 0 ]
    do
        sleep 15
        registeredinstance=$(aws ecs describe-clusters \
        --cluster $Project-$env-report-dc-cluster \
        --query clusters[*].registeredContainerInstancesCount \
        --region $region \
        --output text)
        continue
    done

    services=$(aws ecs list-services \
		--cluster $Project-$env-report-dc-cluster \
    	--query serviceArns \
    	--output text \
    	--region $region)
	for service in $services
    do
        echo "Running tasks and waiting for ecs service $service to be stable"
            aws ecs update-service \
                --cluster $Project-$env-report-dc-cluster \
                --service $service \
                --region $region \
                --desired-count 1 \
             && aws ecs wait services-stable \
        		--service $service  \
        		--cluster $Project-$env-report-dc-cluster \
        		--region $region 
    	if [ $? -eq 0 ]
    	then
        	echo "Tasks of service $service are up and running"
    	else
        	echo "Error in deployment"
        	exit 1
    	fi
    done
}

if [ $action == "stop" ]
then
    stop
    exit 0
elif [ $action == "start" ]
then
    start
    exit 0
fi

if [ $now -eq 20 ] 
then
    stop
elif [ $now -eq 09 ] 
then
    start
fi

