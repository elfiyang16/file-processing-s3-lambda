import boto3
import json
import logging
import os

client = boto3.client("s3")
download_bucket = os.environ['UPLOADER']

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    body = json.loads(event["body"])
    key = body["key"]
    content_type = body["type"]
    logger.info(
        f"Get presigned url for s3://{download_bucket}/{key} ({content_type})")

    params = {
        "Bucket": download_bucket,
        "Key": key,
        "ContentType": content_type
    }

    url = client.generate_presigned_url("put_object", params)

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'url': url
        })
    }
