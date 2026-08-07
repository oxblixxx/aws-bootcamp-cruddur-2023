# Week 0 — Billing and Architecture

## Home work hard assignment

For the Week 0, I learnt quite a number of things.
1. How to draw an architectural diagram on LUCID and napkin diagrams, 
2. About some **AWS SERVICES. AWS ORGANIZATION, AWS CLOUDSHELL.**
3. How to set up a Billing Alarm, Budgets. 

## Create the cruddur logical diagram
![Cruddur](../_docs/assets/cloud.jpeg)

The above architectural diagram is the Cruddur app diagram. Here is the link to view my [logical diagram](https://lucid.app/lucidchart/c31a6be1-a916-4bea-96d9-4aac9027ebff/edit)

Below is a napkin diagram of a vpc with two public public subnets and two private subnets, with NATs gateways in the public subnets and a load balancer to regulate traffic
![napkin-design](assets/napkin.jpg)

***

## Setting up a billing alarm

step 1: Login to your aws account. On the console page click on the downward pointing triangle on the top right corner

![aws-console](assets/billing/billing_00.jpg)

step 2: A box appears, then click on "Billing Dashboard"

![aws-console](assets/billing/billing_01.jpg)

step 3: Thereafter the AWS Billing Dashboard appears. On the left hand side, click "Budgets"

![aws-console](assets/billing/billing_02.jpg)

step 3: Click on "Create a budget"

![aws-console](assets/billing/billing_03.jpg)

step 4: We can use the AWS default template(simplified). Chooe Zero spend budget.

![aws-console](assets/billing/billing_04.jpg)

step 5: Type in our preferred Budget name, Email recipients

![aws-console](assets/billing/billing_05.jpg)

step 6: Then click on "Create Budget"

![aws-console](assets/billing/billing_06.jpg)

step 7: Tadaaaaaa, we created our first Billing alarm, but we have gone beyond the threshold already

![aws-console](assets/billing/billing_07.jpg)

***

## Create a AWS BUDGET

Follow steps above up to step 3

step 4: We can use AWS default template, choose Monthly Cost Budget

![aws-console](assets/billing/billing_09.jpg)

step 5: Type in our preferred Budget Name, budgeted amount and email recipients

![aws-console](assets/billing/billing_10.jpg)

Then Click Create Budget

![aws-console](assets/billing/billing_11.jpg)

***

## Generate AWS Credentials

step 1: Login to your AWS console, on the searchbox type IAM then click enter

![aws-console](assets/billing/billing_00.jpg)

step 2: Scroll down to the Access Keys section, click Create access keys
![aws-console](assets/Credentials/credentials_01.jpg)

step 3: choose Command Line Int

![aws-console](assets/Credentials/credentials_02.jpg)

step 4: Confirm that you understand and click on Next

![aws-console](assets/Credentials/credentials_03.jpg)

step 5: It's best practices to put in a description value, then click Create Access Key

![aws-console](assets/Credentials/credentials_04.jpg)

step 6: You can decide to download the .csv file, click done

![aws-console](assets/Credentials/credentials_06.jpg)

***


##  Install AWS CLI
To install AWS on CLI run

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws configure
```
input the generated IAM user credentials after the prompt when you run AWS CONFIGURE. To confirm if the user is authenticated, run

```
aws sts get-caller-identity
```

![cli-install](Credentials/aws-configure.jpg)













