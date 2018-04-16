# terraform-serverless-spa

Terraformed serverless stack for a VueJS single page app.

AWS infrastructure managed by Terraform:

 * S3 bucket for storing web resources (html,js,images,etc)
 * CloudFront for public content distribution
 * Route53 for DNS with a custom domain name
 * Amazon Certificate Manager issued TLS certificate
 * API Gateway and Lambda serverless backend
 * Cognito User Pool / Federated Identity for authentication


## Prerequisites

 * Amazon AWS account
 * AWS IAM role with a lot of permissions. [iam_policy.json](terraform/iam_policy.json) shows the policy I'm using myself. 
 * Install [AWS cli tools](https://aws.amazon.com/cli/)
  * Arch: pacman -S aws-cli
  * Other: pip install awscli
 * Configure AWS cli for your access credentials:
  * aws configure
  * creates $HOME/.aws/credentials
 * Install [terraform](https://www.terraform.io/downloads.html)
  * Arch: pacman -S terraform
 
 
## Create AWS Infrastructure

 * Edit all the variables in [terraform/vars.tf](terraform/vars.tf) to match your environment.
 * [terraform/main.tf](terraform/main.tf) is the main terraform script to create everything.
 * In the terraform directory run:
  * terraform plan
  * terraform apply (then type 'yes' after reviewing the changes)
  * This will take a LONG time (maybe 1hr+) the first creating the resources.
  * If you see any errors about missing SSL certificate, rerun
    'terraform apply', it should work the 2nd time around.

