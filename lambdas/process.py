import boto3
import logging
import os
import urllib.parse

client = boto3.client("s3")
archive_bucket = os.environ["ARCHIVER"]

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    record = event.get("Records", [])[0]
    eventName = record["eventName"]
    logger.info(
        f"Start to process {eventName}")
    download_bucket = record['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(record['s3']['object']['key'])
    try:
        process(download_bucket, key)
        logger.info(
            f"Moving s3://{download_bucket}/{key} to s3://{archive_bucket}/{key}")
        archive(download_bucket, key)
    except Exception as e:
        logger.exception(
            f"Encounter exception: s3://{download_bucket}/{key}: {e}")


def process(bucket, key):
    meta = client.head_object(Bucket=bucket, Key=key)
    logger.info(
        f"Processing s3://{bucket}/{key} filesize = {meta['ContentLength']}")


def archive(bucket, key):
    client.copy(
        CopySource={'Bucket': bucket, 'Key': key},
        Bucket=archive_bucket,
        Key=key
    )
    client.delete_object(Bucket=bucket, key=key)
