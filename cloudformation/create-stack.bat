rem 1 - stack name
rem 2 - template file name
rem 3 - Subnet CIDR block
rem 4 - Docker image tag

aws cloudformation create-stack --no-verify-ssl --stack-name %1 --template-body file://%2 --parameters ParameterKey=KeyName,ParameterValue=aws_nimbus ParameterKey=InstanceType,ParameterValue=t2.small ParameterKey=SubnetCidrBlock,ParameterValue=%3 ParameterKey=Tag,ParameterValue=%1 ParameterKey=DockerImageTag,ParameterValue=%4