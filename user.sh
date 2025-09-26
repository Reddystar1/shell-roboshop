#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.daws86s.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privilege"
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

##### NodeJS Setup for Amazon Linux 2 #####
yum remove -y nodejs &>>$LOG_FILE
VALIDATE $? "Removing existing NodeJS"

curl -sL https://rpm.nodesource.com/setup_18.x | bash &>>$LOG_FILE
VALIDATE $? "Configuring NodeJS 18 repo"

yum install -y nodejs gcc-c++ make &>>$LOG_FILE
VALIDATE $? "Installing NodeJS 18"

##### App User #####
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exists ... $Y SKIPPING $N"
fi

##### App Setup #####
mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Unzipping user"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying systemd service"

systemctl daemon-reload
systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enabling user service"

systemctl restart user
VALIDATE $? "Starting user service"
