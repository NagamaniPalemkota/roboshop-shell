#!/bin/bash/

USERID=$(id -u)

TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPTNAME=$(echo "$0" | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPTNAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MYSQL_HOST="mysql.muvva.online"

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

dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing Maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOGFILE
VALIDATE $? "downloading shipping code"

cd /app &>> $LOGFILE
VALIDATE $? "changing to app directory"

unzip /tmp/shipping.zip &>> $LOGFILE
VALIDATE $? "unzipping shipping code"

mvn clean package &>> $LOGFILE
VALIDATE $? "cleaning maven package"

mv  target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "renaming jar file"

cp -f /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "copying service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reloading the service"

systemctl enable shipping &>> $LOGFILE
VALIDATE $? "enabling the shipping service"

systemctl start shipping &>> $LOGFILE
VALIDATE $? "starting the shipping service"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>> $LOGFILE
if [ $? -ne 0 ]
then
    echo "Schema is loading:"
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/shipping.sql &>> $LOGFILE
    VALIDATE $? "loading shipping schema into mysql"
else
    echo -e "Schema exists $Y SKIPPING $N"
fi

systemctl restart shipping &>> $LOGFILE
VALIDATE $? "Restarting the shipping service"