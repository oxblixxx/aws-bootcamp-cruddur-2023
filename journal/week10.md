# Week 10 — CloudFormation Part 1

(https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-formats.html)[user-guide]

Cloudformation is an aws service which is an IAC tool, that is used to create and manage infrastructures, infrastructures are  managed in a single unit called stack and it can be written in both yaml and json syntax. Yaml is my preffered, so here is a yaml template.


```yaml
---
AWSTemplateFormatVersion: version date

Description:
  String

Metadata:
  template metadata

Parameters:
  set of parameters

Rules:
  set of rules

Mappings:
  set of mappings

Conditions:
  set of conditions

Transform:
  set of transforms

Resources:
  set of resources

Outputs:
  set of outputs

```

In this project, we will moving the infrastructure to cloudformation a bit at a time, which we will be starting with the network layer first. 


Here are building blocks of a VPC, it's to note that while creating with AWS console, aws manages some creation for us underneath, while creating with an IAC tool, it our full responsibility to set the building block and attach the essentials
```yaml
# AWS VPC Building Blocks

## Core VPC
- VPC
- IPv4 CIDR
- IPv6 CIDR
- DNS Hostnames
- DNS Support
- Tags

## Internet & Egress
- Internet Gateway (IGW) & Internet Gateway Attachment
- NAT Gateway & NAT Gateway Attachment 
- Elastic IP
- Egress-Only Internet Gateway (IPv6)


## Availability Zones

## Subnets
- Public Subnets  - AZ A - AZ B - AZ C
- Private Application Subnets  - AZ A - AZ B - AZ C
- Private Database Subnets  - AZ A - AZ B - AZ C


## Routing
- Public Route Tables
- Private Route Tables
- Database Route Tables
- Routes
- Route Table Associations

## Security
- Application Load Balancer Security Group
- Application Security Group
- Database Security Group
- Management/Bastion Security Group
- Network ACLs
- Security Group Rules
- NACL Rules


## DNS
- Route 53 Private Hosted Zones
- Private DNS Records
- VPC Resolver
- Inbound Resolver Endpoint
- Outbound Resolver Endpoint
- Resolver Rules

## Monitoring & Logging
- VPC Flow Logs
- CloudWatch Log Group
- Flow Logs IAM Role
- S3 Flow Logs Destination
- Log Retention

## DHCP
- DHCP Options Set
- DHCP Options Association

## IPv6
- IPv6 CIDRs
- IPv6 Subnet CIDRs
- IPv6 Routes
- Egress-Only Internet Gateway
- IPv6 Security Group Rules
- IPv6 NACL Rules

```



ERROR ENCOUNTERED

```sh
E0003 /home/sutneppa/aws/cfn/vpc/template.yaml could not be processed by glob.glob
None:1:1


aws: [ERROR]: Invalid endpoint: https://cloudformation..amazonaws.com
```

"Ipv6IpamPoolId cannot be empty."" 


"aws: [ERROR]: An error occurred (ValidationError) when calling the CreateChangeSet operation: Stack:arn:aws:cloudformation:us-east-1:193654356005:stack/cruddur/7e102db0-a0aa-11f1-a0b5-12fe06491577is in ROLLBACK_COMPLETE state and can not be updated."
I got this error while trying to recreate a stack, the issue is that since it failed, i need to delete and recreate