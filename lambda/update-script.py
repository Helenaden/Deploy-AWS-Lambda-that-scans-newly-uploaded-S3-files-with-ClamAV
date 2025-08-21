import os
import boto3
import subprocess
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Set up the S3 client
s3_client = boto3.client('s3')

# Define paths for ClamAV
CLAMAV_DIR = '/tmp/clamav'
CLAMSCAN_CONF = '/etc/clamav/clamd.conf'
FRESHCLAM_CONF = '/etc/clamav/freshclam.conf'
FRESHCLAM_PATH = '/usr/bin/freshclam'

# Ensure the temporary directory for definitions exists
os.makedirs(CLAMAV_DIR, exist_ok=True)
os.environ['CLAMAV_DIR'] = CLAMAV_DIR

def run_freshclam():
    """Runs the freshclam command to download virus definitions."""
    logger.info("Running freshclam to update virus definitions.")
    try:
        subprocess.run(
            [FRESHCLAM_PATH, "--config-file=/etc/freshclam.conf"],
            check=True,
            capture_output=True,
            text=True
        )
        logger.info("Freshclam completed successfully.")
    except subprocess.CalledProcessError as e:
        logger.error(f"Freshclam failed: {e.stderr}")
        raise

def upload_definitions_to_s3(bucket_name):
    """Uploads ClamAV definitions from the temporary directory to S3."""
    logger.info(f"Uploading definitions to S3 bucket: {bucket_name}")
    try:
        for root, dirs, files in os.walk(CLAMAV_DIR):
            for file in files:
                local_path = os.path.join(root, file)
                s3_key = os.path.relpath(local_path, CLAMAV_DIR)
                s3_client.upload_file(local_path, bucket_name, f"clamav/{s3_key}")
                logger.info(f"Uploaded {local_path} to s3://{bucket_name}/clamav/{s3_key}")
    except Exception as e:
        logger.error(f"Error uploading files to S3: {e}")
        raise

def handler(event, context):
    """Lambda handler for the scheduled update."""
    logger.info("Scheduled update function triggered.")
    s3_bucket_name = os.environ.get('CLAMAV_DEFS_BUCKET')
    
    if not s3_bucket_name:
        logger.error("CLAMAV_DEFS_BUCKET environment variable is not set.")
        return

    try:
        # Run freshclam to download definitions
        run_freshclam()

        # Upload the new definitions to S3
        upload_definitions_to_s3(s3_bucket_name)

        logger.info("ClamAV definitions updated successfully.")
        return {
            'statusCode': 200,
            'body': 'Update completed.'
        }
    except Exception as e:
        logger.error(f"An error occurred during the update process: {e}")
        return {
            'statusCode': 500,
            'body': 'Update failed.'
        }