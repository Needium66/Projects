#########################################################################################################################
Building out an AWS API Gateway leveraging Terraform for Microservices that integrates with services that include
payment, telemedicine, pharmacy services, and personal health management. Ensure, the API Gateway routes via the path to 
each of the Microservices. Incorporate the following components below:
-	User management for Login, Session Management, Prompt Management
-	Response Processing
-	Rate Limiting
-	Scalability
###########################################################################################################################
Architecture:
###########################################################################################
+-------------------+
|      Client       |
| (Web/Mobile App)  |
+---------+---------+
          | HTTPS
          v
+-------------------+
| AWS API Gateway   |
| (REST API)        |
|-------------------|
| - Cognito Authorizer|
| - Rate Limiting   |
| - Path-based Routing|
+---------+---------+
          |
          |  /payments
          +----------------> +-------------------+
          |                  | Payment Microservice|
          |                  | (AWS Lambda/ECS)  |
          |                  +-------------------+
          |
          |  /telemedicine
          +----------------> +-------------------+
          |                  | Telemedicine Service|
          |                  | (AWS Lambda/ECS)  |
          |                  +-------------------+
          |
          |  /pharmacy
          +----------------> +-------------------+
          |                  | Pharmacy Service  |
          |                  | (AWS Lambda/ECS)  |
          |                  +-------------------+
          |
          |  /health
          +----------------> +-------------------+
          |                  | Personal Health   |
          |                  | Management Service|
          |                  | (AWS Lambda/ECS)  |
          +-------------------+-------------------+
          |
          |  /users (Login, Session, Prompt)
          +----------------> +-------------------+
                             | User Management   |
                             | (AWS Lambda)      |
                             +-------------------+
