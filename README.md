# Serverless File Scanning with AWS & ClamAV

## Why This Project Matters
Amazon S3 has become the backbone of countless applications on AWS. Its scalability, durability, and ease of use make it the go-to storage layer for many applications hosted on Amazon Web Services (AWS).  

But with great flexibility comes a serious challenge: **untrusted file uploads**.  

When files come from external users, customers, or third-party partners, there’s always a chance they contain malware, ransomware, or viruses. If those files are downloaded by internal teams or downstream users, the consequences can be severe; system compromise, data breaches, reputational damage, and even financial loss.  

The solution to this challenge is to scan every file on upload without slowing users, breaking apps, or racking up costs.
And that’s exactly what this project delivers: secure, scalable malware scanning, invisible to the end user, and cost-effective.
I built a serverless malware scanning system that integrates directly with Amazon S3. It uses AWS-native services + ClamAV inside containerized Lambdas, making it scalable, automated, and cloud-first.

## Here’s the journey of a file through the system:

### 1️⃣ Upload Request
- A user uploads a file through your web portal.
- The request goes through CloudFront, which accelerates delivery worldwide and filters malicious requests with AWS WAF, making sure that security starts from the very first interaction.
- Direct uploads are not allowed. Instead, the app generates a pre-signed URL via API Gateway + Lambda, so files land directly in the correct S3 bucket, fast and secure. 

### 2️⃣ The Hidden Gatekeeper
- Once a file lands in S3, a **Scanner Lambda** is triggered.
- Inside, **ClamAV** (the scanning engine running in a lightweight Docker container) inspects the file, like airport security scanning your luggage.
- This process is fully automated, so you don't need to manually check anything. The scan is designed to be seamless and instant, with no impact on the user experience.

### 3️⃣ Judgment Call
- **If clean** → moved into a secure **Clean Bucket** for downstream use.  
- **If infected** → immediately isolated in a **Quarantine Bucket**.  

### 4️⃣ Instant Awareness
- An **SNS notification** alerts admins in real-time with the scan result,  whether the file is clean or infected.  
- No surprises. No delays. Full visibility.  

## Architecture Components
The system runs on two Docker-based Lambda images, which I built and stored securely in private AWS ECR repositories:  

- **ClamAV Scanner** → Handles file scans on S3 upload events.  
- **ClamAV Updater** → Keeps virus definitions current (triggered by EventBridge).  

## Security Layers
This project follows a **defense-in-depth strategy**:

- **IAM Roles** → Least-privilege access only.  
- **ECR Security** → Private repositories with vulnerability scanning.  
- **Encryption** → S3 server-side encryption with KMS.  
- **Monitoring** → CloudWatch metrics, logs, and alerts.  
- **WAF Integration** → Blocks malicious requests before they reach API Gateway/CloudFront.  

## DevOps & Automation
- **Infrastructure as Code (Terraform)** → Reproducible, consistent deployments.  
- **CI/CD (GitHub Actions + OIDC)** → Secure, keyless AWS authentication.  
- **Static Analysis (Checkov)** → Automated IaC security checks.  
- **Automated Deployments** → From code commit to production with zero manual steps.  

## Performance & Scalability
- **Serverless-first** → Scales automatically, no idle cost.  
- **Fast Uploads** → Pre-signed URLs push files directly into S3.  
- **Optimized Containers** → Faster cold starts for ClamAV Lambdas.  

This design scales effortlessly, from one upload per day to millions per hour.  

## Outcomes
This project successfully delivers:

- ✅ **Security** → Encryption, WAF, IAM, vulnerability scanning  
- ✅ **Production-Ready Architecture** → Scalable, resilient, cost-efficient  
- ✅ **DevOps Excellence** → Terraform IaC + GitHub Actions CI/CD  
- ✅ **Modern Best Practices** → Container-based Lambda, observability built-in  
- ✅ **Business Impact** → Secure uploads, real-time threat detection, user trust  

By combining **serverless scalability with layered security**, this solution makes malware scanning **effortless, invisible, and resilient**.  
Together, it creates a **trust pipeline**, ensuring every file is safe before it’s ever used.  
