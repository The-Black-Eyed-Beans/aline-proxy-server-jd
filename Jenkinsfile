import groovy.json.JsonSlurper

def data = ""

pipeline {
  agent {
    node {
      label "worker-one"
    }
  }

  tools {
    maven 'Maven'
  }

  environment {
    AWS_ACCOUNT_ID = credentials("AWS_ACCOUNT_ID")
    COMMIT_HASH = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
    DOCKER_IMAGE = "proxy-server"
    ECR_REGION = credentials("AWS_REGION")
  }

  stages {
    stage("Init") {
      steps {
        sh 'aws s3 cp s3://beb-bucket-jd/terraform/vpc-output.json vpc-output.json --quiet --profile $AWS_PROFILE'
        sh 'aws s3 cp s3://beb-bucket-jd/terraform/ecs-output.json ecs-output.json --quiet --profile $AWS_PROFILE'
        sh """cat ecs-output.json | jq '.["outputs"]' > ecs.json"""
        sh """cat ecs.json| jq '.["security_groups"]["value"]' | jq 'map({(.name): .id}) | add' > sg.json"""
        sh """cat ecs-output.json | jq '.["service_secrets"]["value"]' | jq 'map({(.name): .arn}) | add' > secrets.json"""
      }
    }
    stage("Test") {
      steps {
        echo "Performing health checks..."
      } 
    }
    stage("Construct Environment") {
      environment {
        VPC = "${sh(script: """cat vpc-output.json | jq -r '.["outputs"]["vpc_id"]["value"]'""", returnStdout: true).trim()} "
        CLUSTER = "${sh(script: """cat ecs.json | jq -r '.["cluster"]["value"]'""", returnStdout: true).trim()}"
        USER_SERVICE = "user-microservice.user-jd.local"
        UNDERWRITER_SERVICE = "underwriter-microservice.underwriter-jd.local"
        ACCOUNT_SERVICE = "account-microservice.account-jd.local"
        TRANSACTION_SERVICE = "transaction-microservice.transaction-jd.local"
        BANK_SERVICE = "bank-microservice.bank-jd.local"
        SG_PRIVATE = "${sh(script: """cat sg.json | jq -r '.["private"]'""", returnStdout: true).trim()}"
        SG_PUBLIC = "${sh(script: """cat sg.json | jq -r '.["public"]'""", returnStdout: true).trim()}"
        SUBNET_ONE = "${sh(script: """cat vpc-output.json | jq -r '.["outputs"]["private_subnets"]["value"][0]'""", returnStdout: true).trim()}"
        SUBNET_TWO = "${sh(script: """cat vpc-output.json | jq -r '.["outputs"]["private_subnets"]["value"][1]'""", returnStdout: true).trim()}"
      }
      steps {
        

        // sh """aws secretsmanager  get-secret-value --secret-id proxy-server-secrets --region us-east-2 --profile joshua | jq -r '.["SecretString"]' | jq '.' > secrets"""
        // sh """aws secretsmanager  get-secret-value --secret-id prod/services --region us-east-2 --profile joshua | jq -r '.["SecretString"]' | jq '.' > secrets.env"""
        // script {
        //   secretKeys = sh(script: 'cat secrets | jq "keys"', returnStdout: true).trim()
        //   secretValues = sh(script: 'cat secrets | jq "values"', returnStdout: true).trim()
        //   secretKeys2 = sh(script: 'cat secrets.env | jq "keys"', returnStdout: true).trim()
        //   secretValues2 = sh(script: 'cat secrets.env | jq "values"', returnStdout: true).trim()
        //   def parser = new JsonSlurper()
        //   def keys = parser.parseText(secretKeys)
        //   def values = parser.parseText(secretValues)
        //   def keys2 = parser.parseText(secretKeys2)
        //   def values2 = parser.parseText(secretValues2)
        //   for (key in keys) {
        //       def val="${key}=${values[key]}"
        //       data += "${val}\n"
        //   }
        //   for (key in keys2) {
        //       def val="${key}=${values2[key]}"
        //       data += "${val}\n"
        //   }
        // }
        // sh "rm -f .env && touch .env"
        // writeFile(file: '.env', text: data)
      }
    }   
    stage("Build Artifact") {
      steps {
        sh "docker context use default"
        sh 'aws ecr get-login-password --region $ECR_REGION --profile joshua | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com'
        sh "docker build -t ${DOCKER_IMAGE} ."
      }
    }
    stage("Upstream Artifact to ECR") {
      steps {
        sh 'docker tag $DOCKER_IMAGE:latest $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:$COMMIT_HASH'
        sh 'docker tag $DOCKER_IMAGE:latest $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:latest'
        sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:$COMMIT_HASH'
        sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:latest'
      }
    }
    stage("Deploy to ECS"){
      steps {
        sh "docker context use prod-jd"
        sh "docker compose -p proxy --env-file ./.env up -d"
      }
    } 
  }
  post {
    cleanup {
      sh "rm -rf ./*"
      sh "docker context use default && docker image prune -af"
    }
  }
}
