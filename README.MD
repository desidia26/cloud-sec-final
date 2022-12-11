# Cloud Sec Final, Fall 2022

## MISSION STATEMENT

For this project, the goal was to come up with a mitigation for a rogue internal server attempting to attack another server within AWS. A better example of this would be that of a bastion host being accessed by a malicious party, and then used to try to gain access to other machines within the internal network. The mitigation should prevent further attacks, as well as notify admins about the occurrence.

## METHOD

The setup is a simple one; two servers would be needed to play the role of victim and attacker. From there the victim would need some way to exhibit the fact that they were under attack, and this would be done through logging. Logs in Cloudwatch would be processed by a Lambda function, and if the logs indicated an attack, the lambda function would do the following:

1. Examine logs for source of the attack. (IP)
2. Create an entry in a DynamoDB table for that IP with the following:
  a. IP (the UID for the table)
  b. Number of incidents related to that IP
  c. Expire time of 6hrs in the future
3. If an entry already existed for the particular IP, its number of incidents would be incremented and its expire time would be pushed forward to $(current_time + 6hrs)
4. If the number of incidents is greater than 10 for the particular IP, the following would occur:
  a. An ACL deny rule would be added to the subnet of the victim server, preventing further traffic from attacker -> victim
  b. An email would be sent to a configured email address, with information about the incident.

## TECHNOLOGIES USED

- AWS
  - Lambda
  - SNS
  - VPC/EC2/ECS
  - IAM
  - Cloudwatch
  - DynamoDB
- Terraform (for AWS resource deployment)
- Golang (used for building the web servers used for testing)
- NodeJS (for the Lambda function)
- Docker (for testing/deployment)

## PROCESS

### CREATING THE SERVERS

Creating the servers, and getting something to work with locally was the first logical step and so two Golang servers were created to test out the attacker -> victim communication. The victim server would have a /login endpoint that accepted a username and password via query parameters, and the attacker would hit that endpoint with invalid credentials. If invalid credentials were received, the victim server would then log out the occurrence, with the IP it came from. From here all that was needed was a way to package the servers and deploy them, this was done using docker.

### DEPLOYING THE SERVERS

At first it was thought that two EC2 instances would be created and used for testing in AWS, however upon further deliberation it was decided that an ECS cluster would be the better/simpler choice due to the smaller amount of overhead/IaC that would need to be written. 

Using Terraform, IaC was created for the deployment of a VPC, subnets, network routing, etc. Then from there the Terraform code for ECS/ECR was made, so that I could test out the two servers communicating within AWS.

### CREATING THE LAMBDA

After the servers were deployed, all that was needed was a Lambda function that subscribed to the Cloudwatch log group that contained the victim server, and acted accordingly. At first the idea was that it would simply take the IP and then block it in the ACL, but then there became an issue of (“well what if its an honest mistake”), so a DynamoDB table was created to track erroneous logins to better detect suspicious activity. Once the logic was in place to detect suspicious activity, the rest was just adding calls to SNS and EC2 for publishing the notifications and updating the ACL to have the corresponding entry.

## CONCLUSION

All-in-all a successful solution. Things that I would like to add on moving forward would be to expire the rules on the ACL as part of a hook into the DynamoDB expiration.


## Instructions for Running (Linux/Mac)

- Ensure `awscli` is [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and configured
- Ensure `terraform` is [installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- ```sh
    git clone https://github.com/desidia26/cloud-sec-final.git
    cd cloud-sec-final/terraform
    terraform apply -auto-approve -var="email=<email_to_receive_notifications>"
  ```
