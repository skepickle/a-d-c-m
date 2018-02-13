#!/bin/bash -xe
# $1 subnet CIDR block
# $2 Docker image tag

# This script gets stored in S3 and is executed on EC2 instances on first launch. The file is referenced by Cloudformation and executed, 
# feeding in the arguments in the template.

export HTTP_PROXY=http://162.95.240.240:8080
export HTTPS_PROXY=${HTTP_PROXY}
export NO_PROXY=localhost,127.0.0.1,169.254.169.254
sudo mkdir /nimbus_clientextensions
sudo -E aws --no-verify-ssl s3 cp s3://client.extension.cm$1/com.a-n.platform.client.extension.cm-0.0.1-SNAPSHOT.jar /nimbus_clientextensions
sudo -E aws --no-verify-ssl s3 cp s3://client.extension.cm/$1/com.a-n.platform.scheduler.extension-0.0.1-SNAPSHOT.jar /nimbus_clientextensions
docker network create --driver bridge nimbus
docker run -d --name=rabbitmq --network=nimbus -p 5672:5672 -p 15672:15672 -p 61613:61613 rabbitmq:3.6.5
docker run -d --name=consul --network=nimbus -p 8500:8500 -p 8300:8300 -p 8600:53 progrium/consul:latest -server -bootstrap -ui-dir /ui
docker run -d --name=neo4j --network=nimbus -p 7474:7474 -v /neo4jdata:/data neo4j:2.3
docker run -d --name=logstash --network=nimbus -p 5000:5000 -v /logstashlogs:/logs logstash:latest
docker run -d --name=elasticsearch --network=nimbus -p 9200:9200 -p 9300:9300 elasticsearch:2.3.3 elasticsearch -Des.network.host=0.0.0.0
docker run -d --name=kibana --network=nimbus -p 5601:5601 kibana:4.5.1
docker run -d --name=mongo --network=nimbus -p 27037:27017 -v /mongodata:/data mongo:2.6.12 mongod
docker run -d --name=mysql --network=nimbus -p 3306:3306 -v /mysqldata:/data/db -e MYSQL_ROOT_PASSWORD=NimbusNonDocker123 mysql:5.7
docker run -d --name=redis --network=nimbus -p 6389:6379 redis:3.2.0
eval '$(aws ecr get-login --region us-east-1 --no-verify-ssl)'
docker run -d --name=config-server --network=nimbus -e SPRING_PROFILES_ACTIVE=docker -e LOG_DIR_PATH=/log -e RABBITMQ_PORT=5672 -e CONFIG_REPO=ssh://git@22.252.129.30/gitdata/$1.git -p 8888:8888 961686557161.dkr.ecr.us-east-1.amazonaws.com/nimbus/com.a-n.platform.core.cloud.config:$2
docker run -d --name=auth-server --network=nimbus -p 8890:8890 -e SPRING_PROFILES_ACTIVE=docker -e LOG_DIR_PATH=/logs -v /nimbuslogs:/logs 961686557161.dkr.ecr.us-east-1.amazonaws.com/nimbus/com.a-n.platform.authentication.web:$2
docker run -d --name=platform-web --network=nimbus -p 8080:8080 -v /nimbus_clientextensions:/clientextensions -e SPRING_PROFILES_ACTIVE=docker -e LOG_DIR_PATH=/logs -e REDIS_PORT=6389 -e MONGO_PORT=27027 -e RABBITMQ_PORT=5672 -e MYSQL_PORT=3306 -v /nimbuslogs:/logs 961686557161.dkr.ecr.us-east-1.amazonaws.com/nimbus/com.a-n.platform.web:$2
docker run -d --name=edge-apigateway --network=nimbus -p 9090:9090 -e SPRING_PROFILES_ACTIVE=docker -e LOG_DIR_PATH=/logs -v /nimbuslogs:/logs 961686557161.dkr.ecr.us-east-1.amazonaws.com/nimbus/com.a-n.platform.edgeapigateway:$2
docker run -d --name=cmapp --network=nimbus -p 3000:3000 -p 3004:3004 961686557161.dkr.ecr.us-east-1.amazonaws.com/nimbus/cmapp:$2
