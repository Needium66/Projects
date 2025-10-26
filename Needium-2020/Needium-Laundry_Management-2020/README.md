########################################################
# Laundry Order Management Using Serverless Architecture
----------------------------------------------------------
This solution uses a serverless stack: "CloudFront/S3/ALB/Lambda/DynamoDB"
The ALB will handle HTTPS termination (port 443 only) and route traffic to the Lambda function; application backend

--------------------------------------------------------------------------------------
Architectural overview and the frontend code that would consume the secure backend API
---------------------------------------------------------------------------------------
.1. Architectural Overview: ALB-Centric Secure Serverless Stack: 

The architecture is designed to enforce HTTPS on all external traffic (port 443 only) and place the compute layer (Lambda) within a private VPC for fine-grained network control, satisfying major core requirements:

A. Network & Security Layer (VPC, ALB, SG)

Component: VPC
----------------
Role: Logical network isolation layer
Security/Port: Contains private subnets for controlled internal resources.

Component:Public Subnets
-------------------------
Role: Host public-facing resources.
Security/Port: ALB is placed here. Needs routing to the Internet Gateway.

Component: Private Subnets
---------------------------
Role:Host private, compute-intensive resources.
Security/Port: Lambda functions are deployed here. Needs routing to the NAT Gateway (in the Public Subnet) for outbound access to public services (like Cognito/S3) or a DynamoDB VPC Endpoint for internal data access.

Component: Route 53
-------------------
Role: DNS and HTTPS Certificate.
Security/Port: Route 53 points the custom domain to the CloudFront distribution (for frontend) and the ALB (for backend API). ACM provides the certificate attached to both CloudFront and the ALB Listeners.

Component: ALB (Application Load Balancer)
------------------------------------------
Role: The HTTPS-only API front door.
Security/Port: Listener: Port 443 (HTTPS) only. Uses the ACM certificate. Target Group: Points to the single Lambda function. Security Group (ALB SG): Inbound Rule: Port 443 (HTTPS) from anywhere (0.0.0.0/0). Outbound Rule: Allows traffic to the Lambda Security Group.


Component:Security Group ( Lambda SG)
-----------------------------
Role: Network control for the compute layer.
Security/Port: Outbound Rule: Allows access to the DynamoDB VPC Endpoint and HTTPS traffic (port 443) via a NAT Gateway for other public AWS services (like Cognito APIs) if needed. Inbound Rule: No inbound rule required since API Gateway is not inside the VPC.


B. Application Layer (Compute, Data, Auth)

Component: Cognito User Pools
------------------------------
Role: Handles user authentication and issues JWTs.
Security/Port: Unchanged from the previous design. The client SDK handles the Sign In/Out flow

Component: Frontend (S3/CF)
----------------------------
Role: Static web application host.
Security/Port: Sends API requests to the ALB's domain, passing the Cognito JWT in the Authorization header.

Component: Lambda
------------------
Role: The unified application backend (handles all /orders and /payments logic).
Security/Port: Routing: Uses the path and HTTP method from the ALB request event to route to the correct business function (e.g., POST /orders runs createOrder, GET /orders runs getOrders). Authorization: Validates the JWT provided in the header against the Cognito JWKS endpoint before executing logic.

Component: DynamoDB
--------------------
Role: Persistent data storage
Security/Port: Stores user data, laundry order details, and payment statuses.
-------------------------------------------------------------------------------------------------------------------------------------

2. Frontend Application: Laundry Management Portal (index.html)
This single-file application uses JavaScript to manage the UI state, handle Cognito authentication, and make secure, authenticated calls (via HTTPS on port 443) to the ALB backend endpoint.

It implements an Application Load Balancer as the secure front door, uses the required VPC and security components (SG, subnets), enforces HTTPS via Port 443, and provides the functional frontend for a Laundry Management web app, including order creation and payment status checks.
-------------------------------------------------------------------------------------------------------------------------------------

.3. Deployment Summary
--------------------------------------

Use Terraform to provision the following in this order:

Networking: Create the VPC, Private Subnets, Public Subnets, Internet Gateway, and NAT Gateway(s).

DNS/Certificate: Create a hosted zone in Route 53. Request an SSL certificate in ACM and validate it via DNS.

Data & Logic: Create the DynamoDB table and the Lambda function with its IAM Execution Role and the associated Security Group (Lambda SG). Configure the Lambda to attach to the private subnets.

Identity: Create the Cognito User Pool.

Frontend Deployment: Create the S3 bucket, configure the CloudFront Distribution using the ACM certificate, and map the Route 53 domain record to the CloudFront distribution. You would update the placeholder UserPoolId, ClientId, ALB in the index.html file before uploading it to S3.
--------------------------------------------------------------------------------------------------------------------------------------

This architecture ensures all traffic flows over Port 443, the application is highly available and scalable using serverless resources, and all network components (VPC, Subnets, SG) are properly utilized for compute isolation.