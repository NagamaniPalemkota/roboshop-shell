#!/bin/bash

instances=("MongoDB" "catalogue" "Redis" "web" "MySQL" "User" "cart" "shipping" "RabbitMQ" "Payment" )
hosted_zone_id=Z09196511SQGIFEK0HWMC
domain_name="muvva.online"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

validate(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R failure $N"
        exit 197
    else
        echo -e "$2 is $G success $N"
    fi
}

for name in ${instances[@]};
do 
    if [ $name == "MySQL" ] || [ $name == "shipping" ]
    then
        instance_type="t3.medium"
    else
        instance_type="t2.micro" #can be t3.micro
    fi
    echo "Creating instance: $name with instance type: $instance_type"
    instance_id=$(aws ec2 run-instances --image-id ami-041e2ea9402c46c32  --instance-type $instance_type  --security-group-ids sg-0068acc7a96fbb265 --query "Instances[0].InstanceId" --output text)
    validate $? "Creating instance $name"

    aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$name
    validate $? "Creating tags for $name"

    if [ $name == "web" ]
    then
        aws ec2 wait instance-running --instance-ids $instance_id
        public_ip=$(aws ec2 describe-instances --filters --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PublicIpAddress]' --output text)
         validate $? "Fetching $public_ip for $name"
        ip=$public_ip
    else
        private_ip=$(aws ec2 describe-instances --filters --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PrivateIpAddress]' --output text)
         validate $? "Fetching $private_ip for $name"
        ip=$private_ip
    fi
    aws route53 change-resource-record-sets --hosted-zone-id  $hosted_zone_id --change-batch '
        {
        "Comment": " creating a record set for $name"
        ,"Changes": [{ 
        "Action": "UPSERT"
        ,"ResourceRecordSet": 
        {
         "Name": "'$name.$domain_name'"
         ,"Type": "A"
         ,"TTL": 1
         ,"ResourceRecords": [{ 
           "Value": "'$ip'" 
          }] 
         } 
           }]
         }
         '
    validate $? "creating/updating route53 record for $name:"
done
