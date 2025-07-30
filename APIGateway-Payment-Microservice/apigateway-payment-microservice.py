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
#TO DO:
#FusionAuth Configuration: Ensuring FusionAuth instance is properly configured to issue JWTs that can be validated by the 
#FusionAuthCustomAuthorizer Lambda. Specifically, the audience in the Lambda code should match what FusionAuth issues for your API
#
#Error Handling and Monitoring: Enhance Lambda error handling and set up more comprehensive CloudWatch alarms
#
#SQS Consumer: Implemening a separate Lambda function (or other service) that consumes messages from the payment-processing-queue 
#to perform the actual background payment processing (e.g., calling a payment gateway, updating status)
#
#DynamoDB Indexes: For efficient querying of payments by userId, perhaps adding a Global Secondary Index (GSI) on the userId attribute
#in the DynamoDB table can be helpful
#
#Input Validation (API Gateway): While Lambda handles validation, API Gateway request validation schemas for stricter input control at
#the edge can be added
#
#Rate Limiting and Throttling: Implement API Gateway usage plans and API keys for rate limiting and throttling to protect the backend services
#
#Regularly review IAM policies for least privilege, enable VPC for Lambdas if accessing private resources, and 
#consider AWS WAF for additional protection
######################################################################################################################################
#Enhancements:
#AWS WAFv2 Integration: Adds a new aws_wafv2_web_acl resource named payment_api_waf. 
#It's configured for REGIONAL scope, suitable for regional API Gateways
#
#The WAF Rules:
#A RateLimitRule to block IPs exceeding 1000 requests within a 5-minute window
#AWS Managed Rule Groups for AWSManagedRulesCommonRuleSet, AWSManagedRulesSQLiRuleSet, and AWSManagedRulesKnownBadInputsRuleSet
#(which includes XSS (Cross-site scripting) protection). These are set to count by default, allowing you to monitor potential threats
#before actively blocking
#
#An aws_wafv2_web_acl_association links this Web ACL to API Gateway stage, ensuring all traffic to API is inspected by WAF
#
#Rate Limiting with Usage Plans and API Keys:
#aws_api_gateway_api_key (payment_api_key) creates a new API key that clients will need to include in their requests.
#aws_api_gateway_usage_plan (payment_usage_plan) defines the throttling (burst and steady-state rates) and quota (monthly limits) for API usage.
#aws_api_gateway_usage_plan_key associates the created API key with this usage plan.
#The api_key_required = true attribute has been added to all aws_api_gateway_method resources
#(POST /payments, GET /payments, GET /payments/{paymentId}), enforcing the use of an API key for access
#
#Input Validation (API Gateway):
#A new aws_api_gateway_model (payment_request_model) is defined. This JSON schema specifies the expected structure and data types for 
#the request body when creating a payment (POST /payments). It enforces amount (number, min 0.01) and currency (3-letter uppercase string) as required fields.
#An aws_api_gateway_request_validator (payment_request_validator) is created to validate the request body against the defined model.
#The post_payments_method now references this request_validator_id and request_models, ensuring that API Gateway automatically 
#validates incoming POST requests before forwarding them to the Lambda function. This offloads validation from your Lambda, 
#improving efficiency and security.
#
#User Management (FusionAuth):
#The existing aws_api_gateway_authorizer and aws_lambda_function.fusionauth_authorizer_lambda continue to handle user authentication 
#and session management via FusionAuth JWTs. This remains the core for user management
#
#Response Processing:
#The AWS_PROXY integration type for Lambda functions ensures that the Lambda's response (including status code, headers, and body)
#is directly passed back to the client by API Gateway, fulfilling the response processing requirement
#
#Scalability and Resilience:
#The inherent scalability of Lambda, API Gateway, SQS, and DynamoDB is maintained.
#AWS WAF adds a layer of security by filtering malicious traffic, protecting backend services.
#API Gateway's built-in rate limiting (via usage plans) prevents abuse and protects services from being overwhelmed.
######################################################################################################################################