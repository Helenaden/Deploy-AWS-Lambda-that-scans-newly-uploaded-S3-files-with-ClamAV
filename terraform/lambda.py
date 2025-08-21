import json
from boto3 import client
from botocore.config import Config
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    AWS Lambda function to generate a pre-signed S3 URL for file uploads.
    It's triggered by an API Gateway request.
    """
    try:
        # Get the bucket name from an environment variable set in Terraform.
        bucket_name = os.environ.get('S3_BUCKET_NAME')
        if not bucket_name:
            return {
                'statusCode': 500,
                'body': json.dumps({'error': 'S3_BUCKET_NAME environment variable not set.'})
            }

        # The file name is expected in the URL path, e.g., /upload/my-file.jpg
        if not event.get('pathParameters') or not event['pathParameters'].get('fileName'):
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'error': 'fileName path parameter is required.'})
            }
        file_name = event['pathParameters']['fileName']

        
        # Initialize the S3 client with signature version 4 for KMS compatibility
        s3_client = client('s3', config=Config(signature_version='s3v4'))
        
        # Generate the pre-signed URL for a PUT request.
        response = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': file_name,
                'ContentType': 'application/octet-stream'
            },
            ExpiresIn=300
        )
        
        # Return the simple URL string in a JSON response.
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,OPTIONS,PUT'
            },
            'body': json.dumps({'uploadUrl': response})
        }
        
    except Exception as e:
        logger.error(f"Error generating pre-signed URL: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'An internal server error occurred.'})
        }
