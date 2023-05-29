Deployments of RDS subnet groups into 6 different environments in AWS.
sandbox - us-east-1 and us-west-1
qa - us-east-1 and us-west-1
development - us-east-1 and us-west-1
build - us-east-1 and us-west-1
production - us-east-1 and us-west-1
dr - us-east-1 and us-west-1
Create a cloudformation template for the deployment
Create a terraform template for the deployment
Let the environment, dbsubnet and regions be parameters.
All these will need to be picked up by the terraform template for the RDS deployments later.