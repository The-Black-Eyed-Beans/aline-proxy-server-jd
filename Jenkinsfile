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
    DOCKER_IMAGE = "proxy-server"
    ECR_REGION = "us-east-2"
    COMMIT_HASH = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
  }

  stages {
    stage("Test") {
      steps {
        echo "Performing health checks..."
      } 
    }
    stage("Construct Environment") {
      steps {
        sh """aws secretsmanager  get-secret-value --secret-id proxy-server-secrets --region us-east-2 --profile joshua | jq -r '.["SecretString"]' | jq '.' > secrets"""
        script {
          secretKeys = sh(script: 'cat secrets | jq "keys"', returnStdout: true).trim()
          secretValues = sh(script: 'cat secrets | jq "values"', returnStdout: true).trim()
          def parser = new JsonSlurper()
          def keys = parser.parseText(secretKeys)
          def values = parser.parseText(secretValues)
          for (key in keys) {
              def val="${key}=${values[key]}"
              data += "${val}\n"
          }
        }
        sh "rm -f .env && touch .env"
        writeFile(file: '.env', text: data)
      }
    }   
    stage("Build Artifact") {
      steps {
        sh "docker context use default"
        sh 'aws ecr get-login-password --region $ECR_REGION --profile joshua | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com'
        sh ". ./.env && docker build -t ${DOCKER_IMAGE} ."
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
