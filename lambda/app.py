import os
import boto3
import json
import logging
from botocore.exceptions import ClientError
from pathlib import Path
import subprocess

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set up the clients
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')

# Define paths for ClamAV
CLAMAV_DIR = '/var/clamav'
CLAMSCAN_PATH = '/usr/bin/clamscan'
FRESHCLAM_PATH = '/usr/bin/freshclam'

# Environment variables
CLEAN_BUCKET = os.environ.get('CLEAN_BUCKET')
QUARANTINE_BUCKET = os.environ.get('QUARANTINE_BUCKET')
CLEAN_TOPIC_ARN = os.environ.get('CLEAN_TOPIC_ARN')
INFECTED_TOPIC_ARN = os.environ.get('INFECTED_TOPIC_ARN')

def download_file_from_s3(bucket, key, download_path):
    """Downloads a file from S3 to a temporary path."""
    try:
        s3_client.download_file(bucket, key, download_path)
        logger.info(f"Successfully downloaded s3://{bucket}/{key} to {download_path}")
    except ClientError as e:
        logger.error(f"Error downloading file: {e}")
        raise

def tag_s3_object(bucket, key, tags):
    """Tags an S3 object with the given key-value pairs."""
    try:
        s3_client.put_object_tagging(
            Bucket=bucket,
            Key=key,
            Tagging={'TagSet': [{'Key': k, 'Value': v} for k, v in tags.items()]}
        )
        logger.info(f"Successfully tagged s3://{bucket}/{key} with {tags}")
    except ClientError as e:
        logger.error(f"Error tagging object: {e}")
        raise

def update_virus_definitions():
    """Updates ClamAV virus definitions."""
    logger.info("Updating ClamAV virus definitions...")
    try:
        # Create a simple freshclam config
        config_content = """DatabaseMirror database.clamav.net
DatabaseDirectory /tmp
UpdateLogFile /tmp/freshclam.log
LogVerbose yes
DNSDatabaseInfo current.cvd.clamav.net
"""
        with open('/tmp/freshclam.conf', 'w') as f:
            f.write(config_content)
        
        result = subprocess.run(
            [FRESHCLAM_PATH, "--config-file=/tmp/freshclam.conf"],
            capture_output=True,
            text=True,
            timeout=120
        )
        logger.info(f"FreshClam output: {result.stdout}")
        if result.stderr:
            logger.warning(f"FreshClam warnings: {result.stderr}")
    except subprocess.TimeoutExpired:
        logger.warning("FreshClam update timed out, proceeding with existing definitions")
    except Exception as e:
        logger.warning(f"Failed to update definitions: {e}")
        
    # Check if definitions were downloaded
    import glob
    cvd_files = glob.glob('/tmp/*.cvd')
    logger.info(f"Downloaded definition files: {cvd_files}")

def scan_file(file_path):
    """Scans a file using ClamAV's clamscan."""
    logger.info(f"Starting ClamAV scan on {file_path}")
    
    result = subprocess.run(
        [CLAMSCAN_PATH, "--database=/tmp", "--verbose", file_path],
        capture_output=True,
        text=True,
        check=False
    )
    
    logger.info(f"ClamAV scan output:\n{result.stdout}")
    
    if "Infected files: 1" in result.stdout:
        return "infected"
    else:
        return "clean"

def move_file_to_bucket(source_bucket, source_key, dest_bucket):
    """Moves a file from source bucket to destination bucket."""
    try:
        # Copy the file to the destination bucket
        s3_client.copy_object(
            CopySource={'Bucket': source_bucket, 'Key': source_key},
            Bucket=dest_bucket,
            Key=source_key
        )
        logger.info(f"Successfully copied s3://{source_bucket}/{source_key} to s3://{dest_bucket}/{source_key}")
        
        # Delete the file from the source bucket
        s3_client.delete_object(Bucket=source_bucket, Key=source_key)
        logger.info(f"Successfully deleted s3://{source_bucket}/{source_key}")
        
    except ClientError as e:
        logger.error(f"Error moving file: {e}")
        raise

def publish_sns_message(topic_arn, subject, message):
    """Publishes a message to a given SNS topic."""
    try:
        sns_client.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=message
        )
        logger.info(f"Published message to SNS topic: {topic_arn}")
    except ClientError as e:
        logger.error(f"Error publishing to SNS topic {topic_arn}: {e}")
        raise

def handler(event, context):
    """Lambda handler function triggered by S3 ObjectCreated events."""
    logger.info("Lambda function triggered by S3 event.")
    
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        # URL decode the key since S3 events may have encoded keys
        import urllib.parse
        key = urllib.parse.unquote_plus(key)
        logger.info(f"Processing file: s3://{bucket}/{key}")
    except (IndexError, KeyError) as e:
        logger.error(f"Error parsing S3 event: {e}")
        return

    download_path = f"/tmp/{os.path.basename(key)}"
    
    try:
        # Update virus definitions first
        update_virus_definitions()
        
        download_file_from_s3(bucket, key, download_path)
        scan_result = scan_file(download_path)
        logger.info(f"File scan result: {scan_result}")
        tag_s3_object(bucket, key, {'av-status': scan_result})
        
        # Move file to appropriate bucket and send notification
        subject = f"File Scan Result: {scan_result.upper()}"
        message = f"Scan of s3://{bucket}/{key} is {scan_result}."
        
        if scan_result == "infected":
            if QUARANTINE_BUCKET:
                move_file_to_bucket(bucket, key, QUARANTINE_BUCKET)
                message += f" File moved to quarantine bucket: {QUARANTINE_BUCKET}"
            if INFECTED_TOPIC_ARN:
                publish_sns_message(INFECTED_TOPIC_ARN, subject, message)
        elif scan_result == "clean":
            if CLEAN_BUCKET:
                move_file_to_bucket(bucket, key, CLEAN_BUCKET)
                message += f" File moved to clean bucket: {CLEAN_BUCKET}"
            if CLEAN_TOPIC_ARN:
                publish_sns_message(CLEAN_TOPIC_ARN, subject, message)
            
    except Exception as e:
        logger.error(f"An error occurred during processing: {e}")
    finally:
        if os.path.exists(download_path):
            os.remove(download_path)
            logger.info(f"Cleaned up temporary file at {download_path}")

    return {
        'statusCode': 200,
        'body': json.dumps('File scan complete!')
    }