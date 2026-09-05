<div align="center">

<img width="1408" alt="CloudOps architecture" src="https://github.com/user-attachments/assets/08383996-8b75-407d-a13c-2a6e452c707f" />

# ☁️ CloudOps: Automated EC2 Auto-Healing & Disaster Recovery Pipeline

  <p><b>A production-grade, fault-tolerant AWS infrastructure featuring an event-driven auto-healing recovery loop.</b></p>

  <p>
    <img src="https://img.shields.io/badge/Terraform-1.0+-purple?style=flat-square&logo=terraform" alt="Terraform">
    <img src="https://img.shields.io/badge/AWS-Lambda%20%7C%20SNS%20%7C%20CloudWatch-orange?style=flat-square&logo=amazonaws" alt="AWS">
    <img src="https://img.shields.io/badge/Ansible-Automation-red?style=flat-square&logo=ansible" alt="Ansible">
    <img src="https://img.shields.io/badge/Python-3.11-blue?style=flat-square&logo=python" alt="Python">
  </p>
</div>

---

## ⚡ Workflow & Execution Loop

* **Detection:** Amazon CloudWatch continuously monitors the primary EC2 instance status. If a hardware or system failure occurs, the metric alarm breaches.
* **Notification:** The alarm routes an alert payload to an Amazon SNS (Simple Notification Service) topic.
* **Remediation:** An AWS Lambda function subscribed to the SNS topic parses the event, terminates the compromised instance, and programmatically spawns a fresh replacement instance using the latest Amazon Linux 2023 AMI.
* **Self-Configuration:** The replacement instance bootstraps instantly using Terraform `user_data` and Ansible-driven configurations to deploy Nginx and custom application states.

---

## 🛠️ Tech Stack & AWS Services

| Category | Technology / Service | Description |
| :--- | :--- | :--- |
| **Infrastructure as Code** | Terraform | Provisioning core VPC, EC2, IAM, and Serverless layers with S3 remote state tracking & DynamoDB locking. |
| **Configuration Management** | Ansible & Bash | Automated provisioning scripts and dynamic inventory handling via `user_data`. |
| **Compute & Networking** | AWS EC2 & VPC | Hosted on `t3.micro` nodes (Amazon Linux 2023) inside a custom public subnet architecture. |
| **Monitoring & Alerting** | CloudWatch & SNS | Real-time health alarm configuration paired with instant event notification routing. |
| **Serverless Automation** | AWS Lambda | Python-powered autonomous healing script handling instance teardown and launch cycles. |
| **Security & Version Control** | IAM & GitHub | Least-privilege IAM roles and policies paired with structured Git version control. |

---

## 📂 Repository Structure

```text
CloudOps_Auto-Healing/
├── ansible/
│   ├── inventory.ini         # Ansible target host configurations
│   └── playbook.yml          # Nginx and configuration playbooks
├── lambda/
│   └── handler.py            # Python serverless remediation logic
├── terraform/
│   ├── backend.tf            # Remote S3 state backend configuration
│   ├── cloudwatch.tf         # CloudWatch alarms and health checks
│   ├── ec2.tf                # EC2 compute node & bootstrap configurations
│   ├── lambda.tf             # Lambda resource deployment and packaging
│   ├── lambda_iam.tf         # Least-privilege IAM roles and permissions
│   ├── provider.tf           # AWS provider and region definitions
│   └── vpc.tf                # Custom VPC, subnets, and internet gateway
├── .gitignore                # Excluded build artifacts, state files, and keys
└── README.md                 # Project documentation
```

## 🚀 Getting Started & Deployment

### Prerequisites
* AWS CLI installed and configured with appropriate permissions (`ap-south-1` region recommended).
* Terraform (`>= 1.0`) installed locally.
* An active SSH key pair named `kv` created in your AWS EC2 console.

### 1. Clone the Repository
```
git clone [https://github.com/sujal2700/CloudOps_Auto-Healing.git](https://github.com/sujal2700/CloudOps_Auto-Healing.git)
cd CloudOps_Auto-Healing
```

### 2. Configure Remote Backend
Ensure your terraform/backend.tf points to your S3 state bucket:

```
terraform {
  backend "s3" {
    bucket         = "cloudops-terraform-state-sujal"
    key            = "auto-healing/terraform.tfstate"
    region         = "ap-south-1"
  }
}
```

### 3. Initialize & Apply Terraform
Navigate to the terraform directory and deploy the stack:
```
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Verify Auto-Healing

To simulate a failure and test the automated recovery workflow:
```
aws ec2 stop-instances --instance-ids <YOUR_INSTANCE_ID> --region ap-south-1
```

Monitor the Lambda execution logs in real time via AWS CloudWatch or the CLI:
```
aws logs tail /aws/lambda/cloudops-auto-healer --follow --region ap-south-1
```
