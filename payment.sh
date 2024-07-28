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

dnf install python3.11 gcc python3-devel -y &>> $LOGFILE
VALIDATE $? "Installing python 3.11"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "User roboshop alreay exists $Y SKIPPING $N"
fi

rm -rf /app &>> $LOGFILE 
VALIDATE $? "removing existing app directory"

mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating directory"

curl -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>> $LOGFILE
VALIDATE $? "downloading payment code"

cd /app &>> $LOGFILE
VALIDATE $? "changing to app directory"

unzip /tmp/payment.zip &>> $LOGFILE
VALIDATE $? "unzipping the code"

pip3.11 install -r requirements.txt &>> $LOGFILE
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/payment.service &>> $LOGFILE
VALIDATE $? "Copying payment service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reloading the service"

systemctl enable payment &>> $LOGFILE
VALIDATE $? "enabling the payment service"

systemctl start payment &>> $LOGFILE
VALIDATE $? "starting the payment service"