Docker Commands

##To build docker image run below command

docker build -t rest-api .

##To run docker container, run below command

docker run -d -p 3000:3000 rest-api

##Create the SSH key pair on your local machine
run below command
1. ssh-keygen -t rsa
2. It will promt for filename: azurekey
3. No passphrase

##Terraform

1. Run terraform plan to make sure everything looks right
2. Run terraform apply
once instance spin up is done verify the connectivity by using SSH
After logging to VM check the docker version and docker container status by running below commands

docker --version
docker ps
