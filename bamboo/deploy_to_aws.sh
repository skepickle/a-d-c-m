#!/bin/sh

if [ "$#" -ne 5 ]; then
 echo "INCORRECT NUMBER OF ARGUMENTS"
 exit 1
fi

STACK_NAME=$1
CFORM_TEMP=$2
CIDR_BLOCK=$3
DOCKER_TAG=$4
META_AGENT=$5

echo "########"
echo "#"
echo "#  Delete running stack: ${STACK_NAME}"
echo "#"
echo "########"
ssh ${META_AGENT} 'bash -s' <<DEL_STACK
 aws --no-verify-ssl --region us-east-1 cloudformation delete-stack --stack-name "${STACK_NAME}"
 aws --no-verify-ssl --region us-east-1 cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}"
DEL_STACK

echo "########"
echo "#"
echo "#  Copy client.extension.cm & scheduler.extension JARs to S3"
echo "#"
echo "########"
scp -r clientextensions/ ${META_AGENT}:~
ssh ${META_AGENT} 'bash -s' <<CLIENT_EXTENSION_CM
 aws --no-verify-ssl s3 cp clientextensions/com.a-n.platform.client.extension.cm-0.0.1-SNAPSHOT.jar s3://client.extension.cm/${CIDR_BLOCK}/
 aws --no-verify-ssl s3 cp clientextensions/com.a-n.platform.scheduler.extension-0.0.1-SNAPSHOT.jar s3://client.extension.cm/${CIDR_BLOCK}/
 rm -rf clientextensions/
CLIENT_EXTENSION_CM

echo "########"
echo "#"
echo "#  Sync configuration repository into AWS Git server"
echo "#"
echo "########"
cd docker-config
# Add remote for AWS repository
git remote add aws ssh://git@22.252.129.30:/gitdata/${CIDR_BLOCK}.git
# Retrieve remote branches from remote AWS repository
git remote update --prune aws
# Delete non-master branches in remote AWS repository
git branch -qa --no-color \
 | grep "^ *remotes\/aws\/[^ ]*$" \
 | sed -e "s/^ *remotes\/aws\///" \
 | grep -v "^master$" \
 | xargs -iBRANCH git push aws :BRANCH
# Push all branchs from remote origin to remote AWS repository
git branch -qa --no-color \
 | grep "^ *remotes\/origin\/[^ ]*$" \
 | sed -e "s/^ *remotes\/origin\///" \
 | grep -v "^master$" \
 | xargs -iBRANCH sh -c 'git checkout BRANCH ; git push aws BRANCH'
git checkout master
git push --force aws master
cd ..

echo "########"
echo "#"
echo "#  Create stack: ${STACK_NAME}"
echo "#"
echo "########"
ls -lFa dev-cfg-mgmt/cloudformation/${CFORM_TEMP}
scp dev-cfg-mgmt/cloudformation/${CFORM_TEMP} ${META_AGENT}:~
ssh ${META_AGENT} 'bash -s' <<CREATE_STACK
 ls -lFa
 aws --no-verify-ssl --region us-east-1 \
  cloudformation create-stack --stack-name "${STACK_NAME}" \
  --template-body file://${CFORM_TEMP} --parameters \
   ParameterKey=KeyName,ParameterValue=aws_nimbus \
   ParameterKey=InstanceType,ParameterValue=m4.large \
   ParameterKey=SubnetCidrBlock,ParameterValue="${CIDR_BLOCK}" \
   ParameterKey=DockerImageTag,ParameterValue="${DOCKER_TAG}"
 rm -f ${CFORM_TEMP}
CREATE_STACK
