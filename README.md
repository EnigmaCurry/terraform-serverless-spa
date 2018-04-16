# terraform-serverless-spa

Terraformed serverless stack for a VueJS single page app.

Example deployment: [www.ts-vue.rymcg.tech](https://www.ts-vue.rymcg.tech)

AWS infrastructure managed via [Terraform](https://terraform.io):

 * [x] S3 bucket for storing web resources (html,js,images,etc)
 * [x] CloudFront for public content distribution
 * [x] Route53 for DNS with a custom domain name
 * [x] Amazon Certificate Manager issued TLS certificate
 * [ ] API Gateway and Lambda serverless backend
 * [ ] Cognito User Pool / Federated Identity for authentication


## Prerequisites

 * Amazon AWS account
 * AWS IAM role with a lot of permissions. 
     * [iam_policy.json](terraform/iam_policy.json) shows the policy I'm using myself. 
 * Your own domain name
     * With the AWS web console, create a Route53 Hosted Zone for the root domain.
     * Configure your domain registrar (whois records) with the AWS
       NS records shown in the Route53 zone. (ns-xxx.awsdns-xxx.xxx)
     * Edit [terraform/vars.tf](terraform/vars.tf) field called
       aws_route53_zone, using the name of the Route53 root zone you
       created in the console.
     * With your root domain now hosted in Route53, this tool can now
       automatically create subdomains using it.
 * Install [AWS cli tools](https://aws.amazon.com/cli/)
     * Arch: pacman -S aws-cli
     * Other: pip install awscli
 * Configure AWS cli for your access credentials:
     * run: aws configure
     * creates $HOME/.aws/credentials
 * Install [terraform](https://www.terraform.io/downloads.html)
     * Arch: pacman -S terraform
 
 
## Create AWS Infrastructure

 * Edit all the variables in [terraform/vars.tf](terraform/vars.tf) to match your environment.
 * [terraform/main.tf](terraform/main.tf) is the main terraform script to create everything.
 * In the terraform directory run:
     * terraform plan
     * terraform apply (then type 'yes' after reviewing the changes)
 * This will take a LONG time (maybe 1hr+) the first time creating the resources.
 * If you see any errors about missing SSL certificate, rerun
   'terraform apply', it should work the 2nd time around.

