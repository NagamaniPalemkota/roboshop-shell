#!/bin/bash

instances=("MongoDB" "catalogue" "Redis" "web" "MySQL" "User" "cart" "shipping" "RabbitMQ" "Payment" )

for name in ${instances[@]}
do 
    if [$name == "MySQL"] || [$name == "shipping"];
    then
        instance_type="t3.medium"
    else
        instance_type="t3.micro"
    fi
    echo "Creating instance: $name with instance type: $instance_type"
done
