// Check required configuration:
var public_html_s3_bucket = process.env.npm_package_config_public_html_s3_bucket;
var aws_cloudfront_distribution = process.env.npm_package_config_aws_cloudfront_distribution;

try {
  if(public_html_s3_bucket == undefined || public_html_s3_bucket == "") {
    throw "You must configure all npm config variables in package.json: missing config variable public_html_s3_bucket";
  }
  if(aws_cloudfront_distribution == undefined || aws_cloudfront_distribution == "") {
    throw "You must configure npm config variables in package.json: missing config variable aws_cloudfront_distribution";
  }
} catch (e) {
  console.error(e);
  process.exit(1);
}

