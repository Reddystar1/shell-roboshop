#!bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
MONGODB_HOST=mongodb.daws86.space
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}
###NodeJS#####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs:20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs -y"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"
mkdir /app 
VALIDATE $? "Creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloding catalogue application"
cd /app 
VALIDATE $? "changing to app directory"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip the catologue"
npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"
cp  catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl servive"
systemctl daemon-reload

systemctl enable catalogue &>>$LOG_FILE 
VALIDATE $? "Enable catalogue"


cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install Mongodb clint"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products"
systemctl Restart catalogue
VALIDATE $? "Restarted catalogue"