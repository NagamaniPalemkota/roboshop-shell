#!/bin/bash/

USERID=$(id -u)

TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPTNAME=$(echo "$0" | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPTNAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R failure $N"
        exit 197
    else
        echo -e "$2 is $G success $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run with super user access"
    exit 1 #manually exiting the code if error comes
else
    echo "You are super user"
fi

curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>> $LOGFILE
VALIDATE $? "Erlang scripts installation"


curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> $LOGFILE
VALIDATE $? "Server scripts installation"

dnf install rabbitmq-server -y &>> $LOGFILE
VALIDATE $? "Installing RabbitMQ Server:"

systemctl enable rabbitmq-server &>> $LOGFILE
VALIDATE $? "enabling RabbitMQ Server:"

systemctl start rabbitmq-server &>> $LOGFILE
VALIDATE $? "starting RabbitMQ Server:"

sudo rabbitmqctl list_users|grep roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    rabbitmqctl add_user roboshop roboshop123 &>> $LOGFILE
    VALIDATE $? "adding roboshop user:"
    rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGFILE
    VALIDATE $? "setting permissions to roboshop user:"
else
    echo -e "User already exists $Y SKIPPING $N"
fi