#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename $0 .sh)
SCRIPT_DIR=$PWD
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

log_and_run() {
    echo "$1" | tee -a $LOG_FILE
    eval "$1" &>>$LOG_FILE
    VALIDATE $? "$2"
}

# Install Nginx
log_and_run "dnf module disable nginx -y" "Disabling default Nginx"
log_and_run "dnf module enable nginx:1.24 -y" "Enabling Nginx module"
log_and_run "dnf install nginx -y" "Installing Nginx"

# Remove default content and deploy frontend
log_and_run "rm -rf /usr/share/nginx/html/*" "Cleaning default frontend"
log_and_run "curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip" "Downloading frontend"
log_and_run "cd /usr/share/nginx/html && unzip /tmp/frontend.zip" "Extracting frontend"

# Deploy nginx.conf
if [ -f $SCRIPT_DIR/nginx.conf ]; then
    cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
    VALIDATE $? "Copying nginx.conf"
else
    echo -e "Custom nginx.conf missing ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
fi

# Resolve microservice hostnames and inject into /etc/hosts
MICROSERVICES=(catalogue user cart shipping payment)
DOMAIN="daws86.space"

for service in "${MICROSERVICES[@]}"; do
    IP=$(dig +short "$service.$DOMAIN")
    if [ -z "$IP" ]; then
        echo -e "$R Could not resolve $service.$DOMAIN $N" | tee -a $LOG_FILE
    else
        echo "$IP $service.$DOMAIN" | sudo tee -a /etc/hosts
        echo -e "$G Added $service.$DOMAIN -> $IP to /etc/hosts $N" | tee -a $LOG_FILE
    fi
done

# Validate nginx config
nginx -t &>>$LOG_FILE
VALIDATE $? "Validating Nginx config"

# Enable and start nginx
log_and_run "systemctl enable nginx" "Enabling Nginx"
log_and_run "systemctl restart nginx" "Restarting Nginx"
