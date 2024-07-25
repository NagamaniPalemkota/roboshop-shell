#!/bin/bash

instances=("MongoDB" "catalogue" "Redis" "web" "MySQL" "User" "cart" "shipping" "RabbitMQ" "Payment" )
hosted_zone_id=Z09196511SQGIFEK0HWMC
domain_name="muvva.online"
for name in ${instances[@]};
do 
    if [ $name == "MySQL" ] || [ $name == "shipping" ]
    then
        instance_type="t3.medium"
    else
        instance_type="t3.micro"
    fi
    echo "Creating instance: $name with instance type: $instance_type"
    instance_id=$(aws ec2 run-instances --image-id ami-041e2ea9402c46c32  --instance-type $instance_type  --security-group-ids 
	sg-0068acc7a96fbb265  --subnet-id subnet-0717dc25807226641 --query "Reservations[].Instances[].InstanceId" --output text)

    aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$name

    if [ $name == "web" ]
    then
        aws ec2 wait instance-running --instance-ids $instance_id
        public_ip=$(ec2 describe-instances --filters "Name=instance_id,Values=$instance_id --query 'Reservations[0].Instances[0].[PublicIpAddress]' --output text)
        ip=$public_ip
    else
        private_ip=$(ec2 describe-instances --filters "Name=instance_id,Values=$instance_id --query 'Reservations[0].Instances[0].[PrivateIpAddress]' --output text)
        ip=$private_ip
    fi
    aws route53 change-resource-record-sets --hosted-zone-id  $hosted_zone_id --change-batch 
        '{ 
        "Comment": " creating a record set for $name", 
        "Changes": [ { 
        "Action": "UPSERT", 
        "ResourceRecordSet": 
        {
         "Name": "$name.$domain_name",
          "Type": "A", 
          "TTL": 1, 
          "ResourceRecords": [ { "Value": "$ip" } ] 
        } 
        } ]
         }'
done
