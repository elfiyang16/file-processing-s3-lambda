import boto3
import json
import logging
import os

bucket = os.environ['UPLOADER']
role_arn = os.environ['ASSUMED_ROLE_ARN']
sts_client = boto3.client('sts')

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    body = json.loads(event["body"]
                      )
    key = body["key"]
    session_name = f"{context.aws_request_id}"
    session_policy = {
        'Version': '2012-10-17',
        'Statement': [
            {
                'Effect': 'Allow',
                'Action': 's3:PutObject',
                "Resource": f"arn:aws:s3:::{bucket}/{key}"
            }
        ]
    }

    logger.info(
        f"Generating restricted credentials for: s3://{bucket}/{key} for session {session_name}")

    res = sts_client.asssume_role(
        RoleArn=role_arn,
        RoleSessionName=session_name,
        Policy=json.dumps(session_policy)
    )
    creds = res['Credentials']

    logger.info(
        f"Assumed role arn is: {role_arn}")

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'access_key':     creds['AccessKeyId'],
            'secret_key':     creds['SecretAccessKey'],
            'session_token':  creds['SessionToken'],
            'region':         os.environ['AWS_REGION'],
            'bucket':         bucket
        })
    }
