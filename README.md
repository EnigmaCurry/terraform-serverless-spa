# terraform-serverless-spa

Terraformed serverless stack for a VueJS single page app.

Example deployment: [ts-vue.rymcg.tech](https://ts-vue.rymcg.tech)

AWS infrastructure automatically managed via [Terraform](https://terraform.io):

 * [x] S3 bucket for storing web resources (html,js,images,etc)
 * [x] CloudFront for public content distribution
     * [x] Deployment time cache invalidation, for fast iteration
 * [x] Route53 for DNS with a custom domain name
 * [x] Amazon Certificate Manager issued TLS certificate
 * [ ] API Gateway for lambda function backend.
 * [ ] Cognito User Pool / Federated Identity for authentication

Directories:
 * app - The single page app is a typescript VueJS frontend generated
via [vue-cli](https://github.com/vuejs/vue-cli).
 * chalice - The serverless backend is Python 3, with the help of
[Chalice](http://chalice.readthedocs.io).
 * terraform - All infrastructure for AWS is declaratively described,
   deployed, and lifecycle managed via [Terraform](https://terraform.io).
      
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
     * Arch: ```pacman -S aws-cli```
     * Other: ```pip install awscli```
 * Configure AWS cli for your access credentials:
     * Run: ```aws configure```
     * This creates $HOME/.aws/credentials
     * Be mindful of your own system security. That file is
       unprotected and provides access to your AWS account. When
       you're done with your terraform deployment, just delete this
       file. In the AWS console, create a seperate IAM User that only
       has access to the S3 bucket that ```npm run deploy``` uses. If you
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
     * Arch: ```pacman -S terraform```
 * Install Python 3.6 (or latest)
     * Arch: ```pacman -S python3```
 
## Create AWS Infrastructure

 * Edit all the variables in [terraform/vars.tf](terraform/vars.tf) to match your environment.
 * [terraform/main.tf](terraform/main.tf) is the main terraform script
   to create everything.
 * In the terraform directory run:
     * ```terraform plan```
     * ```terraform apply``` (then type 'yes' after reviewing the changes)
     * If you want to destroy it later (ie stop paying for it):
       terraform destroy
 * This will take a LONG time (maybe 1hr+) the first time creating the
   resources.
 * If you see any errors about missing SSL certificate, rerun
   ```terraform apply```, it should work the 2nd time around.
 * The final output terraform shows is called 'Outputs'. Make a note
   of this information, it lists the IDs of some of the resources
   created. Run ```terraform refresh``` if you need to see them again.
 * Even after ```terraform apply``` is finished, Amazon is still
   performing a few actions in the background. In the AWS console,
   check the CloudFront distribution status, as well as the
   Certificate Manager validation status. Wait for these to show a
   completed status, so that you know everything is setup
   successfully.

## Deploy Chalice lambda functions

 * From the chalice directory, run:
     * ```npm run config```
     * ```npm run chalice-env```
 * Config does the following:
     * Collects data from terraform
     * Creates chalice/.npmrc with necessary variables
     * .npmrc overrides the default (blank) config in package.json
     * (.npmrc is in .gitignore, so it is only a local config)
 * Chalice-env creates a Python virtual environment in which to
   install dependencies.
 * Package the chalice apps (writes to chalice/dist):
     * ```npm run package```
   
If you need to interact with chalice directly, you can enter the
virtual environment:

 * Run: ```source chalice-env/bin/activate```
 * Do what you need to.
 * When done, deactivate the virtual environment:
     * Run: ```deactivate```
     

## Deploy frontend app

 * From the app directory, run:
     * ```npm install```
     * ```npm run config```
     * ```npm run deploy```
 * Config does the following:
     * Collects data from terraform
     * Creates app/.npmrc with necessary variables
     * .npmrc overrides the default (blank) config in package.json
     * (.npmrc is in .gitignore, so this is a local instance config)
 * Deploy does the following things:
     * Checks the config variables exist (either by .npmrc or package.json)
     * Builds the app into the dist/ directory.
     * Uploads the dist/ directory to S3 via ```aws s3 sync```.
     * Invalidates the CloudFront cache for index.html
         * This avoids you having to wait for the CloudFront cache TTL
           to run out on the old index.html (Default TTL is 1hr.)
         * index.html is the only file that needs invalidation. All
           the rest of the files in the app have versioned filenames,
           and so won't ever need invalidation.
         * Note: the first 1000 cache invalidations per month are
           free. After that, you start paying Amazon for each
           invalidation (half a penny or so each time.) Which should
           be plenty, as long as you're developing locally and deploying
           only to staging/production environments.
     * Waits for the CloudFront cache invalidation to finish.

Your app should now be visible at the frontend URL you configured in
[terraform/vars.tf](terraform/vars.tf).

