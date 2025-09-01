import json
import boto3

def lambda_handler(event, context):
    ses = boto3.client('ses', region_name='ap-south-1')
    pipeline_name = event['detail']['pipeline']
    state = event['detail']['state']
    stage = event['detail'].get('stage', 'N/A')
    subject = f"AWS Pipeline Notification: {pipeline_name} - {state}"
    body = f"Pipeline: {pipeline_name}\nStage: {stage}\nState: {state}\n\nDetails:\n{json.dumps(event, indent=2)}"
    response = ses.send_email(
        Source='madheshilango23@gmail.com',
        Destination={'ToAddresses': ['madheshilango23@gmail.com']},
        Message={'Subject': {'Data': subject}, 'Body': {'Text': {'Data': body}}}
    )
    return {'statusCode': 200, 'body': json.dumps('Email sent')}
