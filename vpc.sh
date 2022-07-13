#!/bin/bash


#for custom EC2 parameters

VPC_cidr=10.0.0.0/16
VPC_name=MYvpc
Subnet_name=MYsubnet
Subnet_cidr=10.0.0.0/24
Subnet2_name=MYsubnet2
Subnet2_cidr=10.0.2.0/24
Igw_name=MYgateway
Rtb_name=MYroute_table
Sec_gr_name=MYsecuryt_group
Sec_gr_descr=AMI_users
Instance_name=Ubuntu
ami=ami-052efd3df9dad4825
count=1
t2=t2.micro
key=rsa
#for custom s3 bucket parameters
bucket_name=zaq11qaz
#region=us-east-1

#for custom Iam user parameters

user=S3
group=Admin
#password=My!User1Login8P@ssword
policy=arn:aws:iam::aws:policy/AdministratorAccess





#if any error checked, start removing functions




delete-security-group () { aws ec2 delete-security-group \
                        --group-id $SG_ID
}

#removing subnet

delete-subnet () { aws ec2 delete-subnet \
                 --subnet-id $Subnet_ID
}

#removing subnet2

delete-subnet2 () { aws ec2 delete-subnet \
                 --subnet-id $Subnet2_ID
}

#disassiciating route table

disassociate-rtb () { aws ec2 disassociate-route-table \
	--association-id $Asociate
}

#removing route table

delete-rtb () { aws ec2 delete-route-table \
          --route-table-id $RTB_ID
}


#deataching internet gateway from VPC

detach-gateway () { aws ec2 detach-internet-gateway \
           --internet-gateway-id $IGW_ID \
           --vpc-id $VPC_ID
}

#removing internet gateway
delete-gateway () { aws ec2 delete-internet-gateway \
            --internet-gateway-id $IGW_ID
}



#removing VPC
delete-vpc () { aws ec2 delete-vpc \
	     --vpc-id $VPC_ID
}



#removing Key Pair
delete-KeyPair () { aws ec2 delete-key-pair \
	      --key-name $key
                rm -f $key.pem
}


##############################################################

#Creating VPC

        VPC_ID=$(aws ec2 create-vpc \
	--cidr-block $VPC_cidr \
	--query Vpc.{Vpcid:VpcId} \
	--output text)

 if [ ! $? = 0  ]

then
	echo "something wrong with vpc"
        echo "------------------------------"
        exit 1

else

#Add tags to vpc

         aws ec2 create-tags \
         --resources $VPC_ID \
         --tags Key=Name,Value=$VPC_name

          echo "VPC is created. VPC ID is $VPC_ID"
fi

##############################################################

#Creating Subnet

SUBNET_ID=$(aws ec2 create-subnet \
	--vpc-id $VPC_ID \
	--cidr-block $Subnet_cidr \
	--query Subnet.SubnetId \
	--output text)

if  [ -s $SUBNET_ID ]

then
     echo "something wrong with subnet"
     delete_vpc
     echo "------------------------------"
     exit 1


else

#Add tags to subnet
        aws ec2 create-tags \
        --resources $SUBNET_ID \
        --tags Key=Name,Value=$Subnet_name

       echo "Subnet is created. Subnet ID is $SUBNET_ID"
fi

######################################################################

#Creating second Subnet

SUBNET2_ID=$(aws ec2 create-subnet \
        --vpc-id $VPC_ID \
        --cidr-block $Subnet2_cidr \
        --query Subnet.Subnet2Id \
        --output text)

if  [ -s $SUBNET2_ID ]

then
     echo "something wrong with subnet"
     delete_vpc
     echo "------------------------------"
     exit 1


else

#Add tags to subnet
        aws ec2 create-tags \
        --resources $SUBNET2_ID \
        --tags Key=Name,Value=$Subnet2_name

       echo "Subnet2 is created. Subnet2 ID is $SUBNET2_ID"
fi


#Creating Internet Gateway

IGW_ID=$(aws ec2 create-internet-gateway \
	--query InternetGateway.InternetGatewayId \
	--output text)

if [ -s $IGW_ID ]


then
       	echo "something wrong with gateway"
        delete-subnet
	delete-subnet2
        delete-vpc
	echo "------------------------------"
        exit 1

else

#Add tags to gateway

	aws ec2 create-tags \
        --resources $IGW_ID \
        --tags Key=Name,Value=$Igw_name

echo "Gateway is created. Gateway ID is $IGW_ID"

fi

#################################################################

#Attach gateway to VPC

        aws ec2 attach-internet-gateway \
	--vpc-id $VPC_ID \
	--internet-gateway-id $IGW_ID

if [ ! $? = 0 ]

then
	echo "something wrong with attaching to gateway"
        detach-gateway
        delete-subnet
        delete-subnet2
        delete-vpc
        exit 1
fi

##################################################################

#creating route table

RTB_ID=$(aws ec2 create-route-table \
	--vpc-id $VPC_ID \
	--query RouteTable.RouteTableId \
	--output text)

if [ -z $RTB_ID ]
then
	echo "something wrong with routing table"
        detach-gateway
	delete-gateway
	delete-subnet
        delete-subnet2
        delete-vpc

	echo "------------------------------"
        exit 1

else

#Add tags to route table

         aws ec2 create-tags \
        --resources $RTB_ID \
        --tags Key=Name,Value=$Rtb_name

echo "Route table is created. Route table ID is $RTB_ID"

fi

#################################################################

#Associate route tabe to subnet

ASSOCIATE=$(aws ec2 associate-route-table \
	--subnet-id $SUBNET_ID \
        --route-table-id $RTB_ID \
	--query "AssociationId" \
	--output text)

if [ -s $ASSOCIATE ]
then
        echo "Something wrong with subnet"
	delete-rtb
	detach-gateway
	delete-gateway
	delete-subnet
	delete-subnet2
        delete-vpc
	echo "------------------------------"
	exit 1

else

      echo "Route table $RTB_ID is associated with subnet $SUBNET_ID "

fi





#################################################################

#crating default route

        DEF_ROUTE=$(aws ec2 create-route \
        --route-table-id $RTB_ID \
        --destination-cidr-block 0.0.0.0/0 \
	--gateway-id $IGW_ID \
	--output text)
	if [ ! $? = 0 ]

then
        echo "Something wrong with 0.0.0.0 route"
        disassociate-rtb
        delete-rtb
	detach-gateway
        delete-gateway
        delete-subnet
        delete-subnet2
        delete-vpc
        echo "------------------------------"
        exit 1
else 

      echo "Default route to 0.0.0.0 is crated"

fi

##################################################################

#creating security group

SG_ID=$(aws ec2 create-security-group \
	--vpc-id $VPC_ID \
	--group-name $Sec_gr_name \
	--description $Sec_gr_descr \
	--query GroupId \
	--output text)

if [ -s $SG_ID ]

then
	echo "Something wrong with security group"
	disassociate-rtb
        delete-rtb
        detach-gateway
        delete-gateway
        delete-subnet
        delete-subnet2
        delete-vpc

	echo "------------------------------"
        exit 1

else

#add tags to security group

        aws ec2 create-tags \
	--resources $SG_ID \
	--tags Key=Name,Value=MYSG
fi

#################################################################

#Creating remote SSH connection rules for created security group and authorize sec groupe

#opening ssh 22 port

        aws ec2 authorize-security-group-ingress \
	--group-id $SG_ID \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0 > /dev/null
       echo "SSH 22 port is open"

#openning http 80 port

        aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 > /dev/null
      echo "HHTP 80 port is open"

#openning https 443 port

        aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 > /dev/null
      echo "HHTPS 443 port is open"

###########################################################################
#crating ssh key, and checking for key duplicate, if key exists, remove it

#creating SSH key


if
     	[ -f $key.pem ]

then
	delete-KeyPair
        echo "------------------------------"
       	exit 1

else
       	aws ec2 create-key-pair \
	--key-name $key \
	--query "KeyMaterial" --output text > $key.pem

	chmod 400 $key.pem

	echo "Key with name rsa crated"
fi


######################################################

############################################################
#crating S3 bucket

         BUCKET_ID=$(aws s3 mb s3://$bucket_name)
         echo "BUCKET_ID"
         echo "S3 bucket is added"


###########################################################
#uplpading site refresh scrypt to bucket and make publc
              aws s3 cp refresh.sh s3://$bucket_name

          echo "refresh.sh scrypt uploaded to bucket"

###########################################################
#make uploaded objects public-read

                #aws s3api put-object-acl \
		#--bucket $bucket_name \
		#--key index.html \
		#--acl public-read

		#aws s3api put-object-acl \
                #--bucket $bucket_name \
                #--key nginx.sh \
                #--acl public-read

		aws s3api put-object-acl \
                --bucket $bucket_name \
                --key refresh.sh \
                --acl public-read
		echo "Files are Public"

###############################################################
#create IAM user for s3 bucket

           IAM_userID=$(aws iam create-user \
           --user-name $user \
           --query 'User.UserId' \
           --output text)

           echo "Iam S3 $user is created"

#######################################################################
#attach full access to user

           aws iam attach-user-policy \
           --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
           --user-name $user

            echo "$user full access policy is crated"

####################################################################
#catch Iam user credentials

CRED=$(aws iam create-access-key \
  --user-name $user \
  --query "AccessKey.[AccessKeyId,SecretAccessKey]" \
  --output text)
###################################################################

ACCESS_KEY_ID=$(echo $CRED | awk '{print $1}')
SECRET_ACCESS_KEY=$(echo $CRED | awk '{print $2}')

echo  "$ACCESS_KEY_ID":"$SECRET_ACCESS_KEY" > s3.cred.txt
echo  "$ACCESS_KEY_ID":"$SECRET_ACCESS_KEY" > .passwd-s3fs

echo "$ACCESS_KEY_ID:$SECRET_ACCESS_KEY added to .passwd-s3fs file"
chmod 600 .passwd-s3fs

echo "Added chmod 666 permision to .passwd-s3fs"


###################################################################
#running EC2 Instance with public address association

INSTANCE_ID=$(aws ec2 run-instances \
	--image-id $ami \
	--count $count \
	--instance-type $t2 \
	--key-name $key \
	--security-group-ids $SG_ID \
	--subnet-id $SUBNET_ID \
	--associate-public-ip-address \
	--query 'Instances[*].InstanceId' \
	--output text)


if [ -z $INSTANCE_ID ]

then
	 echo "something wrong with instance"
	      disassociate-rtb
              delete-rtb
              delete-security-group
	      detach-gateway
              delete-gateway
              delete-subnet
              delete-subnet2
              delete-KeyPair
	      delete-vpc
          echo "------------------------------"
	  exit 1

else
       	aws ec2 create-tags \
        --resources $INSTANCE_ID \
        --tags Key=Name,Value=Test_ubuntu

fi


#########################################################

#checking created Instance public ip address


         aws ec2 wait instance-running \
        --instance-ids $INSTANCE_ID
	aws ec2 describe-instances \
	--query 'Reservations[*].Instances[*].State.Name' \
	--instance-ids $INSTANCE_ID \
	--output text
	PUBLIC_IP=$(aws ec2 describe-instances \
	--instance-ids $INSTANCE_ID \
	--query 'Reservations[*].Instances[*].PublicIpAddress' \
	--output text)


         #PUBLIC_IP=$(aws ec2 describe-instances \
         #--instance-ids $INSTANCE_ID \
         #--query "Reservations[*].Instances[*].PublicIpAddress" \
	 #--output text)

echo "instance ip is $PUBLIC_IP"

           ssh-keyscan $PUBLIC_IP >> ~/.ssh/known_hosts
           echo "SSH key added to Known_Hosts!!!"

echo "Adding all id-s to CATCH_ALL_ID file"

echo $VPC_ID >> CATCH_ALL_ID
echo $SUBNET_ID >> CATCH_ALL_ID
echo $SUBNET2_ID >> CATCH_ALL_ID
echo $ASSOCIATE >> ASSOC_ID
echo $RTB_ID >> CATCH_ALL_ID
echo $IGW_ID >> CATCH_ALL_ID
echo $SG_ID >> CATCH_ALL_ID 
echo $INSTANCE_ID > INSTANCE_ID
echo $PUBLIC_IP > PUBLIC_IP
echo $DEF_ROUTE >> CATCH_ALL_ID
#echo $Bucket_ID > CATCH_ALL_ID
echo $IAM_userID > IAM_ID
echo $bucket_name >> CATCH_ALL_ID

##########################################################

#copy ssh.key to known hosts

       aws ec2 wait instance-status-ok \
       --instance-ids $INSTANCE_ID

       echo "Waiting istance running"
       echo "Starting mount bucket to s3volume on instance $INSTANCE_ID"

       scp -i $key.pem .passwd-s3fs ubuntu@$PUBLIC_IP:/home/ubuntu
       scp -i $key.pem install.sh ubuntu@$PUBLIC_IP:/home/ubuntu
       #ssh -i $key.pem ubuntu$PUBLIC_IP "mkdir s3Volume"
       ssh -i $key.pem ubuntu@$PUBLIC_IP "./install.sh"






##################################################################
#starting mount bucket to s3Volume

#echo "Starting mount bucket to s3volume on instance $Instance_ID"
#######################################################################



#scp -oStrictHostKeyChecking=accept-new -i $key.pem .passwd-s3fs ubuntu@$(cat $PUBLIC_IP):/home/ubuntu/.passwd-s3fs

#########################################################################
#ssh -oStrictHostKeyChecking=accept-new -i $key.pem ubuntu@$(cat PUBLIC_IP):"install.sh" && "mkdir ~/s3Volume" && "sudo s3fs $bucket_name /home/ubuntu/s3Volume/ \-o allow_other \-o use_path_request_style \-o passwd_file=/home/ubuntu/.passwd-s3fs \-o nonempty -o rw\-o mp_umask=002 -o uid=1000 -o gid=1000" && "sudo chmod 755 /home/ubuntu*" && "sudo chmod 644 /home/ubuntu/s3Volume/*"





##############################################################################
#ssh -oStrictHostKeyChecking=accept-new -i $key.pem ubuntu@$(cat PUBLIC_IP):"mkdir ~/s3Volume"

###############################################################################
#ssh -oStrictHostKeyChecking=accept-new -i $key.pem ubuntu@$(cat PUBLIC_IP):"sudo s3fs $bucket_name /home/ubuntu/s3Volume/ \-o allow_other \-o use_path_request_style \-o passwd_file=/home/ubuntu/.passwd-s3fs \-o nonempty -o rw\-o mp_umask=002 -o uid=1000 -o gid=1000" 

###############################################################################
#ssh -oStrictHostKeyChecking=accept-new -i $key.pem ubuntu@$(cat PUBLIC_IP):"sudo chmod 755 /home/ubuntu*"

##############################################################################
#ssh -oStrictHostKeyChecking=accept-new -i $key.pem ubuntu@$(cat PUBLIC_IP):"sudo chmod 644 /home/ubuntu/s3Volume/*"
	
echo "created s3Volume directory ec2 and mounted s3 bucket"


echo "DONE"
echo "instance ip is $PUBLIC_IP"

