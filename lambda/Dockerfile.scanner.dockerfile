# Use the official AWS Lambda Python 3.9 base image
FROM public.ecr.aws/lambda/python:3.9

# Install ClamAV and clamav-update
RUN yum install -y clamav clamav-update --setopt=tsflags=nodocs && yum clean all

# Create a directory for ClamAV definitions
RUN mkdir -p /var/clamav

# Copy your Lambda function code
COPY app.py ${LAMBDA_TASK_ROOT}/

# Set the CMD to your Lambda handler
CMD ["app.handler"]
