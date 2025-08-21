# Start from the official AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.9

# Install ClamAV and its dependencies
RUN yum install -y clamav clamav-update

# Set a working directory
WORKDIR /var/task

# Copy the Python handler code
COPY update-script.py .

# Command to run the handler
CMD ["update-script.handler"]