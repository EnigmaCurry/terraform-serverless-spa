# terraform-serverless-spa

Terraformed serverless stack for a VueJS single page app.

Example deployment: [ts-vue.rymcg.tech](https://ts-vue.rymcg.tech)

AWS infrastructure automatically managed via [Terraform](https://terraform.io):

 * [x] S3 bucket for storing web resources (html,js,images,etc)
 * [x] CloudFront for public content distribution
 * [x] Route53 for DNS with a custom domain name
 * [x] Amazon Certificate Manager issued TLS certificate
 * [ ] API Gateway and Lambda serverless backend
 * [ ] Cognito User Pool / Federated Identity for authentication


## Prerequisites

 * Amazon AWS console account.
 * AWS IAM user account with an attached policy/group with a lot of permissions. 
     * Create this user in the AWS IAM console manually, then copy
       the Access and Secret keys into your password manager or
       whatever you use to keep things safe.
     * You need to attach a policy to the IAM user or group to allow
       it access to the necessary services.
       [iam_policy.json](terraform/iam_policy.json) shows the IAM
       policy that I'm using myself. It's a lot of permissions, as
       this script will need access to a wide variety of AWS services.
 * Your own domain name
     * With the AWS web console, create a Route53 Hosted Zone for the root domain.
     * This part could have been part of the script, but because I
       will use this hosted zone in multiple projects, beyond just
       this one, I do this part manually in the console.
     * Configure your domain registrar (whois records) with the AWS
       NS records shown in the Route53 zone. (ns-xxx.awsdns-xxx.xxx)
     * Edit [terraform/vars.tf](terraform/vars.tf) field called
       aws_route53_zone, replacing the default value with the name of
       the Route53 root zone you created in the console.
     * With your root domain now hosted in Route53, this tool can now
       automatically create subdomains and TLS certificates using it.
 * Install [AWS cli tools](https://aws.amazon.com/cli/)
     * Arch: pacman -S aws-cli
     * Other: pip install awscli
 * Configure AWS cli for your access credentials:
     * Run: aws configure
     * This creates $HOME/.aws/credentials
     * Be mindful of your own system security. That file is
       unprotected and provides access to your AWS account. When
       you're done with your terraform deployment, just delete this
       file. In the AWS console, create a seperate IAM User that only
       has access to the S3 bucket that 'npm run deploy' uses. If you
       need to run terraform again, just run 'aws configure' again,
       and retyping the credentials that you saved from before.
     * For a more permanent installation, you might use an AWS EC2
       t2.nano instance, that you leave running forever, only SSH
       access, with login requiring key and [two factor
       authentication](https://medium.com/aws-activate-startup-blog/securing-ssh-to-amazon-ec2-linux-hosts-18e9b72319d4).
       In the AWS console you can assign the EC2 instance itself an
       IAM role with the same policy. Then you ssh to that secure box,
       and run terraform from there. Because the instance itself has
       the IAM role, you don't need to configure or manage any AWS
       credentials on the machine.
 * Install [terraform](https://www.terraform.io/downloads.html)
     * Arch: pacman -S terraform
 
 
## Create AWS Infrastructure

 * Edit all the variables in [terraform/vars.tf](terraform/vars.tf) to match your environment.
 * [terraform/main.tf](terraform/main.tf) is the main terraform script to create everything.
 * In the terraform directory run:
     * terraform plan
     * terraform apply (then type 'yes' after reviewing the changes)
     * If you want to destroy it later (ie stop paying for it): terraform destroy
 * This will take a LONG time (maybe 1hr+) the first time creating the resources.
 * If you see any errors about missing SSL certificate, rerun
   'terraform apply', it should work the 2nd time around.

## Deploy app

 * Edit [app/package.json](app/package.json) and find the "deploy" script and change the s3 bucket name to your own.
 * From the app directory, run:
     * npm install
     * npm run deploy
 * Deploy will build the SPA application to the dist/ directory and
   the run 'aws s3 sync' to copy the built website to the S3 bucket
   that cloudfront pulls from.
   
At this point, you wait. As described in more detail in the notes inside [terraform/main.tf](terraform/main.tf), Amazon needs to do a few things in the background:

 * Verify your TLS certificate through the Route53 DNS entries created by this script.
 * Configure all the cloudfront endpoints.
 * This can take an hour.
 * Check the Cloudfront and Certificate Manager consoles for current status.

Once everything is done, your app should be visible at the frontend
URL you configured in [terraform/vars.tf](terraform/vars.tf). You're just waiting for the tasks performed in 'terraform apply' to take effect. 'npm run deploy' will be fast for subsequent deployments.
