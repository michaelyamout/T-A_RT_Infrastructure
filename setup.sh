#!/bin/bash

set -e

# Function to install dependencies
install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y python3-pip terraform ansible awscli
    pip3 install boto3 botocore
}

# Check and install required tools
for cmd in terraform ansible aws; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Installing dependencies..."
        install_dependencies
        break
    fi
done

# Prompt for AWS credentials if not set
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
    export AWS_ACCESS_KEY_ID
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    read -p "Enter your AWS Secret Access Key: " -s AWS_SECRET_ACCESS_KEY
    echo
    export AWS_SECRET_ACCESS_KEY
fi

# Prompt for AWS region
read -p "Enter your preferred AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

# Prompt for user's IP
read -p "Enter your IP address for SSH access (e.g., 123.456.789.0): " YOUR_IP

# Create terraform.tfvars
cat > terraform/terraform.tfvars << EOF
aws_region = "${AWS_REGION}"
your_ip    = "${YOUR_IP}"
EOF

# Generate SSH key pair if it doesn't exist
if [ ! -f terraform/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f terraform/id_rsa -N ""
fi

# Initialize and apply Terraform
cd terraform
terraform init
terraform apply -auto-approve

# Generate Ansible inventory from Terraform output
terraform output -json > output.json
cd ..

# Generate Ansible inventory using Python
python3 - << 'EOF'
import json

with open('terraform/output.json') as f:
    output = json.load(f)

inventory = """[sliver_c2]
{} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/id_rsa sliver_c2_private_ip={}

[redirector]
{} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/id_rsa

[attacker]
{} ansible_user=ubuntu ansible_ssh_private_key_file=../terraform/id_rsa
""".format(
    output['sliver_c2_public_ip']['value'],
    output['sliver_c2_private_ip']['value'],
    output['redirector_public_ip']['value'],
    output['attacker_workstation_public_ip']['value']
)

with open('ansible/inventory.ini', 'w') as f:
    f.write(inventory)
EOF

# Run Ansible playbook
cd ansible
ansible-playbook -i inventory.ini site.yml

echo "Deployment complete!"
