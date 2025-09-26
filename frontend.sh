#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename $0 .sh)
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.daws86.space
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

# Install Nginx
dnf module disable nginx -y &>>$LOG_FILE
dnf module enable nginx:1.24 -y &>>$LOG_FILE
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

# Remove default content and deploy frontend
rm -rf /usr/share/nginx/html/*
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Downloading & Extracting frontend"

# Deploy custom nginx.conf
if [ -f $SCRIPT_DIR/nginx.conf ]; then
    cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
    VALIDATE $? "Copying nginx.conf"
else
    echo -e "Custom nginx.conf missing ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
fi

echo "172.31.xx.xx catalogue.daws86.space" | sudo tee -a /etc/hosts
echo "172.31.yy.yy user.daws86.space" | sudo tee -a /etc/hosts
echo "172.31.zz.zz cart.daws86.space" | sudo tee -a /etc/hosts
echo "172.31.aa.aa shipping.daws86.space" | sudo tee -a /etc/hosts
echo "172.31.bb.bb payment.daws86.space" | sudo tee -a /etc/hosts

# Validate nginx config
nginx -t &>>$LOG_FILE
VALIDATE $? "Validating Nginx config"

# Enable and start nginx
systemctl enable nginx &>>$LOG_FILE
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Enabling & Starting Nginx"
