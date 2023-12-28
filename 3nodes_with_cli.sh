#!/bin/bash
# 1. CLI commands to create VPC
aws ec2 create-vpc \
	--cidr-block 10.2.0.0/16 \
	--tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=vpc-shared},{Key=Project,Value=weclouddata}]' > /dev/null

#2. CLI commands to create subnet
aws ec2 create-subnet \
	--vpc-id $(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=vpc-shared" --query 'Vpcs[0].VpcId' --output text) \
	--cidr-block 10.2.254.0/24 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=pub-subnet-nat},{Key=Project,Value=weclouddata}]' > /dev/null

#3a.CLI commands to create internet gateway - part 1/2 : creation
aws ec2 create-internet-gateway \
	--tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=igw-vpc-shared},{Key=Project,Value=weclouddata}]' > /dev/null

#3b.CLI commands to create internet gateway - part 2/2 : attachment
aws ec2 attach-internet-gateway \
	--internet-gateway-id $(\
		aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=igw-vpc-shared" --query 'InternetGateways[].InternetGatewayId' --output text) \
	--vpc-id $(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.2.0.0/16" --query 'Vpcs[].VpcId' --output text)

#4a.CLI commands to create route table - part 1/3 : creation
aws ec2 create-route-table \
	--vpc-id $(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.2.0.0/16" --query 'Vpcs[].VpcId' --output text) \
	--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=rt-nat-pub},{Key=Project,Value=weclouddata}]' > /dev/null
#4a.CLI commands to create route table - part 2/3 : association
aws ec2 associate-route-table \
	--route-table-id $(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=rt-nat-pub" --query 'RouteTables[].RouteTableId' --output text) \
	--subnet-id $(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.2.254.0/24" --query 'Subnets[].SubnetId' --output text) > /dev/null
#4c.CLI commands to create route table - part 3/3 : destination
aws ec2 create-route \
	--route-table-id $(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=rt-nat-pub" --query 'RouteTables[].RouteTableId' --output text) \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $(\
		aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=\
		$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.2.0.0/16" --query 'Vpcs[].VpcId' --output text)" \
			--query 'InternetGateways[].InternetGatewayId' --output text) > /dev/null

#5a.CLI commands to create security group - part 1/3 : creation
aws ec2 create-security-group --group-name vpc-shared-sg --description "Web Security Group" \
	--vpc-id $(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=vpc-shared" --query 'Vpcs[0].VpcId' --output text) > /dev/null
#5b.CLI commands to create security group - part 2/3 : tagging
aws ec2 create-tags \
	--resources $(aws ec2 describe-security-groups --filters Name=group-name,Values=vpc-shared-sg --query 'SecurityGroups[*].GroupId' --output text) \
	--tags Key=Name,Value=vp-shared-sg Key=Project,Value=weclouddata
#5c.CLI commands to create security group - part 3/3 : authorization
aws ec2 authorize-security-group-ingress  --group-id $(aws ec2 describe-security-groups --filters Name=group-name,Values=vpc-shared-sg --query 'SecurityGroups[].GroupId' --output text) --protocol all --port -1 --cidr 0.0.0.0/0 > /dev/null

#6.three EC2 creations
aws ec2 run-instances \
--image-id ami-06aa3f7caf3a30282 \
--count 1 --instance-type t2.small \
--key-name wcd-projects \
--security-group-ids $(aws ec2 describe-security-groups --filters Name=group-name,Values=vpc-shared-sg --query 'SecurityGroups[].GroupId' --output text) \
--subnet-id $(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.2.254.0/24" --query "Subnets[].SubnetId" --output text) \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=master-node-1},{Key=Project,Value=weclouddata}]" \
--associate-public-ip-address \
--user-data file://python310.txt > /dev/null
aws ec2 run-instances \
--image-id ami-06aa3f7caf3a30282 \
--count 1 --instance-type t2.micro \
--key-name wcd-projects \
--security-group-ids $(aws ec2 describe-security-groups --filters Name=group-name,Values=vpc-shared-sg --query 'SecurityGroups[].GroupId' --output text) \
--subnet-id $(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.2.254.0/24" --query "Subnets[].SubnetId" --output text) \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=worker-node-1},{Key=Project,Value=weclouddata}]" \
--associate-public-ip-address \
--user-data file://python310.txt > /dev/null
aws ec2 run-instances \
--image-id ami-06aa3f7caf3a30282 \
--count 1 --instance-type t2.micro \
--key-name wcd-projects \
--security-group-ids $(aws ec2 describe-security-groups --filters Name=group-name,Values=vpc-shared-sg --query 'SecurityGroups[].GroupId' --output text) \
--subnet-id $(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.2.254.0/24" --query "Subnets[].SubnetId" --output text) \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=worker-node-2},{Key=Project,Value=weclouddata}]" \
--associate-public-ip-address \
--user-data file://python310.txt > /dev/null

# #THESE ARE CLI Commands to delete all resources above in the reverse order
# #CLI commands to delete security group
# aws ec2 delete-security-group --group-id $(aws ec2 describe-security-groups --filters Name=group-name,Values=vpc-shared-sg --query 'SecurityGroups[].GroupId' --output text)
# #CLI commands to disassociate route tables
# aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.2.254.0/24" --query 'Subnets[].SubnetId' --output text)" --query 'RouteTables[].Associations[].RouteTableAssociationId' --output text)
# #CLI commands to delete route tables
# aws ec2 delete-route-table --route-table-id $(aws ec2 describe-route-tables --query 'RouteTables[?Associations == `[]`].RouteTableId' --output text)
# #CLI commands to detach internet gateway
# aws ec2 detach-internet-gateway --internet-gateway-id $(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=igw-vpc-shared" --query 'InternetGateways[].InternetGatewayId' --output text) --vpc-id $(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.2.0.0/16" --query 'Vpcs[].VpcId' --output text)
# #CLI commands to delete internet gateway
# aws ec2 delete-internet-gateway --internet-gateway-id $(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=igw-vpc-shared" --query 'InternetGateways[].InternetGatewayId' --output text)
# #CLI commands to delete subnet
# aws ec2 delete-subnet --subnet-id $(aws ec2 describe-subnets --filters "Name=cidr-block,Values=10.2.254.0/24" --query "Subnets[].SubnetId" --output text)
# #CLI commands to delete VPC
# aws ec2 delete-vpc --vpc-id $(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.2.0.0/16" --query 'Vpcs[0].VpcId' --output text)    