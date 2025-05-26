#!/bin/bash

set -e  # Exit on any error

# Check if environment argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <environment>"
    echo "Environment must be one of: dev, test, prod"
    exit 1
fi

ENV=$1

# Validate environment
if [[ ! "$ENV" =~ ^(dev|test|prod)$ ]]; then
    echo "Error: Environment must be one of: dev, test, prod"
    exit 1
fi

# Check if tfvars file exists
if [ ! -f "${ENV}.tfvars" ]; then
    echo "Error: ${ENV}.tfvars file not found"
    exit 1
fi

echo "Setting up $ENV environment..."

# Select the desired workspace 
terraform workspace select $ENV || terraform workspace new $ENV

# init
terraform init

# Make sure we start with a blank slate
echo "Destroying existing infrastructure..."
terraform destroy -auto-approve -var-file $ENV.tfvars

# Get the correct image tag from tfvars
IMAGE_TAG=$(grep 'image_tag' $ENV.tfvars | cut -d '"' -f 2)

# Make sure the image exists
echo "Building Docker image: demo-clicker:$IMAGE_TAG"
docker build -t demo-clicker:$IMAGE_TAG .

# Build the infrastructure (cluster first)
echo "Creating Kind cluster..."
terraform apply -auto-approve -target=kind_cluster.default -var-file $ENV.tfvars

# Set up the environment variable for kubectl
export KUBECONFIG=~/.kube/config-$ENV

# Deploy the app
echo "Deploying application..."
terraform apply -auto-approve -var-file $ENV.tfvars

echo "Deployment complete!"
echo "Access your application at: http://$(grep 'ingress_host' $ENV.tfvars | cut -d '"' -f 2)"
echo "KUBECONFIG is set to: $KUBECONFIG"
