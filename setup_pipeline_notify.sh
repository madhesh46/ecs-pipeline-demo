#!/bin/bash

# Variables
PIPELINE_NAME="ecs-pipeline"
GMAIL="madheshilango23@gmail.com"
LAMBDA_ROLE="LambdaSESPipelineRole"
LAMBDA_NAME="PipelineNotifyLambda"
RULE_NAME="ecs-pipeline-rule"
REGION="ap-south-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Step 1: Create IAM Role for Lambda
aws iam create-role --role-name $LAMBDA_ROLE --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "lambda.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}'

# Attach policies
aws iam attach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/AmazonSESFullAccess
aws iam attach-role-policy --role-name $LAMBDA_ROLE --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Step 2: Create Lambda Python script
cat <<EOL > pipeline_notify.py
import json
import boto3

def lambda_handler(event, context):
    ses = boto3.client('ses', region_name='$REGION')
    pipeline_name = event['detail']['pipeline']
    state = event['detail']['state']
    stage = event['detail'].get('stage', 'N/A')
    subject = f"AWS Pipeline Notification: {pipeline_name} - {state}"
    body = f"Pipeline: {pipeline_name}\\nStage: {stage}\\nState: {state}\\n\\nDetails:\\n{json.dumps(event, indent=2)}"
    response = ses.send_email(
        Source='$GMAIL',
        Destination={'ToAddresses': ['$GMAIL']},
        Message={'Subject': {'Data': subject}, 'Body': {'Text': {'Data': body}}}
    )
    return {'statusCode': 200, 'body': json.dumps('Email sent')}
EOL

zip pipeline_notify.zip pipeline_notify.py

# Step 3: Create Lambda Function
aws lambda create-function \
  --function-name $LAMBDA_NAME \
  --runtime python3.11 \
  --role arn:aws:iam::$ACCOUNT_ID:role/$LAMBDA_ROLE \
  --handler pipeline_notify.lambda_handler \
  --zip-file fileb://pipeline_notify.zip

# Step 4: Create EventBridge Rule for Pipeline
aws events put-rule \
  --name $RULE_NAME \
  --event-pattern "{
    \"source\": [\"aws.codepipeline\"],
    \"detail-type\": [\"CodePipeline Pipeline Execution State Change\"],
    \"detail\": {
      \"pipeline\": [\"$PIPELINE_NAME\"],
      \"state\": [\"SUCCEEDED\",\"FAILED\"]
    }
  }"

# Step 5: Add Lambda as Target
aws events put-targets \
  --rule $RULE_NAME \
  --targets "Id"="1","Arn"="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$LAMBDA_NAME"

# Step 6: Give EventBridge Permission to Invoke Lambda
aws lambda add-permission \
  --function-name $LAMBDA_NAME \
  --statement-id EventBridgeInvoke \
  --action "lambda:InvokeFunction" \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:$REGION:$ACCOUNT_ID:rule/$RULE_NAME

echo " EventBridge + Lambda + SES setup complete. Test by pushing code to $PIPELINE_NAME!"

