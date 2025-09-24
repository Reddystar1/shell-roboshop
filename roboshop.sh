#!bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0d1e1b3241c4a66bd"
for instance in $@
do
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro 
--security-group-ids sg-0d1e1b3241c4a66bd --tag-specifications "ResourceType=instance,Tags=[{Key=Name,
Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

#get private ip
if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids i-0d56a98415b5d6773 
    --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
else
    IP=$( aws ec2 describe-instances --instance-ids i-0d56a98415b5d6773 
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
fi

echo "$instance: $IP"
done