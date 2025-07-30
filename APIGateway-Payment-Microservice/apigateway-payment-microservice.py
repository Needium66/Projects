####################################################
#Payment Service
###################################################
# A Payment Microservice
##################################################################################################################
#Objective is to build out a Payment service supported by a Microservice with the below components:
#- API Gateway(Frontend): to route traffic/requests to respective Lambda microservices
#- Fusion Auth(Frontend): the identity provider for authentication/authorization of users
#- Lambda(Backend): A FusionAuth custom authorizer for the authentication/authorization and a Payment Processor for the payment logic
#- SQS(Frontend): for the aysnchronous processing of payment requests
#- DynamoDb(Backend): to store unstructured data; payment transaction details
######################################################################################################################################
#Key Components
#IAM:
#Role and Policy: To define the necessary permissions for Lambda functions to interact with CloudWatch (for logging),
#DynamoDB (for data storage), and SQS (for asynchronous messaging)
#
#DynamoDB Table: To store payment transaction details. It uses PAY_PER_REQUEST billing mode for cost efficiency and automatic scaling
#
#SQS Queue: For asynchronous processing of payment requests, enhancing resilience and decoupling the payment creation from immediate processing
#
#Lambda:
#FusionAuthCustomAuthorizer: This Lambda acts as a custom authorizer for API Gateway. It validates JWTs (JSON Web Tokens) issued 
#by FusionAuth instance
#PaymentProcessorService: This Lambda handles the core payment logic. It receives requests from API Gateway, stores payment details in 
#DynamoDB, and sends messages to the SQS queue for further asynchronous processing. It also handles retrieving payment details
#
#Others:
#aws_api_gateway_rest_api: Defines the main REST API endpoint for your payment service.
#aws_api_gateway_authorizer: Configures the custom authorizer that uses the FusionAuthCustomAuthorizer Lambda to authenticate incoming requests.
#aws_api_gateway_resource: Defines the API paths: /payments and /payments/{paymentId}.
#aws_api_gateway_method: Specifies the HTTP methods (POST, GET) allowed on these paths and links them to the custom authorizer for authentication.
#aws_api_gateway_integration: Connects the API Gateway methods to the PaymentProcessorService Lambda using AWS_PROXY integration, which passes the entire request context to the Lambda.
#aws_lambda_permission: Grants API Gateway the necessary permissions to invoke Lambda functions.
#aws_api_gateway_deployment: Deploys the API Gateway configuration. A new deployment is triggered whenever API Gateway resources change.
#aws_api_gateway_stage: Creates a named stage (e.g., dev) for your API deployment, allowing for versioning and environment-specific
#configurations. It also configures access logging to CloudWatch.
#aws_cloudwatch_log_group: Sets up a log group for API Gateway access logs, providing visibility into API traffic.
#output: Provides the invoke URL of deployed API Gateway, which frontend application will use to interact with the payment service
#######################################################################################################################################