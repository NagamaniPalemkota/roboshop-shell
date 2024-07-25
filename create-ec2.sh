#!/bin/bash

instances = ("MongoDB" "catalogue" "Redis" "web" "MySQL" "User" "cart" "shipping" "RabbitMQ" "Payment" )

for name in ${instances[@]}
do 
    echo ("Creating instance $name")
done
