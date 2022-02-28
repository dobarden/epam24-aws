

# About Project

This Terraform code deploys WordPress CMS in AWS Cloud. The following infrastructure is being created:

1) VPC, Subnets, Route Tables, Internet Gateway
2) EC2 instances, RDS MySQL, EFS, ALB
3) Security Groups for EC2, RDS, EFS, ALB

# Project usage

## Add credentials for your IAM user
1. export AWS_ACCESS_KEY_ID=...
2. export AWS_SECRET_ACCESS_KEY=...

## Creating the Infrastructure
1. git clone https://github.com/dobarden/epam24-aws.git
2. cd epam24-aws/
3. terraform init
4. terraform apply

When infrastructure is deployed you can use WordPress. Find a link called "ALB-dns-name" in the "Outputs" section. Past this link in a browser.

## Destroying the Infrastructure
1. cd epam24-aws/
2. terraform destroy
