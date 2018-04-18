// Reads JSON input from 'aws cloudfront create-invalidation'
// Parses the AWS Invalidation ID
// Waits for the cache invalidation to finish

var stdin = process.stdin,
    inputChunks = [],
    util = require('util'),
    child_process = require('child_process');

stdin.resume();
stdin.setEncoding('utf-8');

stdin.on('data', (chunk) => {
  inputChunks.push(chunk);
});

stdin.on('end', () => {
  var json = inputChunks.join(),
      data = JSON.parse(json),
      invalidationID = data['Invalidation']['Id'],
      cmd = util.format('aws cloudfront wait invalidation-completed --distribution-id %s --id %s',
                        process.env.npm_package_config_aws_cloudfront_distribution, invalidationID);
  // Wait for the invalidation to finish:
  console.log("Waiting for CloudFront cache invalidation to finish...");
  child_process.execSync(cmd);
});
