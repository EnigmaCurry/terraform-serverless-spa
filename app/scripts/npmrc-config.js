// Discover resources from terraform output and configure .npmrc

const { spawn } = require('child_process'),
      fs = require('fs'),
      util = require('util'),
      required_fields = ['public_html_s3_bucket',
                         'aws_cloudfront_distribution'],
      terraform_output_re = /^([^ ]+) = ([^ ]+)$/;

// Get the name of the app from package.json
let packagejson = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
const app_name = packagejson.name;

// Gather output fields from Terraform and create .npmrc

const proc = spawn('terraform', ['output', '-state=../terraform/terraform.tfstate']);
let terraform_output = [];
let terraform_fields = {};

proc.stdout.on('data', (data) => {
  terraform_output.push(data.toString());
});

proc.stdout.on('end', () => {
  terraform_output = terraform_output.join('').split('\n');
  let npmrc_stream = fs.createWriteStream('.npmrc');
  terraform_output.forEach((line) => {
    let match = terraform_output_re.exec(line);
    if (match && required_fields.includes(match[1])) {
      npmrc_stream.write(util.format('%s:%s=%s\n', app_name, match[1], match[2]));
    }
  });
  npmrc_stream.end();
  console.log("Collected Terraform data and wrote ./.npmrc");
});
