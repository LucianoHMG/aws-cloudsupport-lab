#!/bin/bash

# AWS CloudFormation Deploy Script
# Cloud Support Lab

set -e

echo "[*] AWS Cloud Support Lab - Deploy Script"
echo "[*] This script will create the infrastructure using CloudFormation"
echo ""

# Variables
STACK_NAME="cloudsupport-lab"
TEMPLATE="cf-template.yaml"
REGION="us-east-1"

# Check prerequisites
echo "[+] Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    echo "[!] AWS CLI not found. Please install it first."
    exit 1
fi

echo "[+] Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "[!] AWS credentials not configured."
    exit 1
fi

echo "[+] Current AWS Account: $(aws sts get-caller-identity --query Account --output text)"
echo "[+] Region: $REGION"
echo ""

# Get SSH Key Name
echo "[?] Available EC2 Key Pairs:"
aws ec2 describe-key-pairs --region $REGION --query 'KeyPairs[*].KeyName' --output table

read -p "[?] Enter your EC2 Key Pair name: " KEY_NAME

if [ -z "$KEY_NAME" ]; then
    echo "[!] Key pair name cannot be empty."
    exit 1
fi

echo "[+] Using Key Pair: $KEY_NAME"
echo ""

# Deploy CloudFormation Stack
echo "[*] Creating CloudFormation stack..."
aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://$TEMPLATE \
    --parameters ParameterKey=KeyName,ParameterValue=$KEY_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

echo "[+] Stack creation initiated. Waiting for completion..."
echo "[*] This may take several minutes..."
echo ""

aws cloudformation wait stack-create-complete \
    --stack-name $STACK_NAME \
    --region $REGION

echo "[+] Stack created successfully!"
echo ""
echo "[*] Stack Outputs:"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs' \
    --output table

echo ""
echo "[+] Deployment completed!"
echo "[*] Next steps:"
echo "    1. SSH into Web Server: ssh -i your-key.pem ec2-user@<WebServerPublicIP>"
echo "    2. For Private DB access: aws ssm start-session --target <DB-Instance-ID>"
echo "    3. Check CloudWatch logs: aws logs describe-log-groups --region $REGION"
