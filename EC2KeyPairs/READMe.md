Deployment of EC2 key pairs to 2 different regions in 6 environments in AWS.
sandbox - us-east-1 and us-west-1
qa - us-east-1 and us-west-1
development - us-east-1 and us-west-1
build - us-east-1 and us-west-1
production - us-east-1 and us-west-1
dr - us-east-1 and us-west-1
Generate the EC2 key pair externally.
Store the private key in passwordstate.
Deploy a cloudformation template with these key pairs into the specified environments
Deploy a terraform template with these key pairs.
Ensure a consistent naming convention that have the environment, region and some others as parameters.
The end goal is to have the ec2 key pairs picked up by terraform for servers deployment for the apps migration.