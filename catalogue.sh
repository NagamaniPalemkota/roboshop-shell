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

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "disabling mongodb"

dnf module enable nodejs:20 -y &>> $LOGFILE
VALIDATE $? "eanbling nodejs"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing nodejs"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "User roboshop alreay exists $Y SKIPPING $N"
fi


mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "downloading catalogue code"

cd /app &>> $LOGFILE
VALIDATE $? "changing to app directory"


unzip /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "unzipping the code"

npm install &>> $LOGFILE
VALIDATE $? "installing dependencies"

cp /home/ec2-user/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "copying catalogue service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reloading the service"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "enabling the catalogue service"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "starting the catalogue service"

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "copying mongo.repo file"

dnf install -y mongodb-mongosh &>> $LOGFILE
VALIDATE $? "installing mongodb client mongosh"

mongosh --host mongodb.muvva.online </app/schema/catalogue.js &>> $LOGFILE
VALIDATE $? "loading the schema to mongodb"