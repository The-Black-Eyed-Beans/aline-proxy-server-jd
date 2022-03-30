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
    AWS_PROFILE = credentials("AWS_PROFILE")
    COMMIT_HASH = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
    DOCKER_IMAGE = "proxy-server"
    ECR_REGION = credentials("AWS_REGION")
  }

  stages {
    stage("Test") {
      steps {
        echo "Performing health checks..."
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
    stage("Fetch Environment Variables"){
      steps {
        script {
          try{
            sh "aws lambda invoke --function-name getProxyServerEnv data.json --profile $AWS_PROFILE"
          }catch (Exception e){
            currentBuild.result = "ABORTED"
            error("Failed to get environment variables! Someone should be alerted! =O")
          }
        }
      }
    }
    stage("Update Proxy Server Service"){
      environment {
        CLUSTER = "${sh(script: """cat data.json | jq -r '.["body"]["CLUSTER"]'""", returnStdout: true).trim()}"
        SG_PRIVATE = "${sh(script: """cat data.json | jq -r '.["body"]["SG_PRIVATE"]'""", returnStdout: true).trim()}"
        SG_PUBLIC = "${sh(script: """cat data.json | jq -r '.["body"]["SG_PUBLIC"]'""", returnStdout: true).trim()}"
        SUBNET_ONE = "${sh(script: """cat data.json | jq -r '.["body"]["SUBNET_ONE"]'""", returnStdout: true).trim()}"
        SUBNET_TWO = "${sh(script: """cat data.json | jq -r '.["body"]["SUBNET_TWO"]'""", returnStdout: true).trim()}"
        VPC = "${sh(script: """cat data.json | jq -r '.["body"]["VPC"]'""", returnStdout: true).trim()}"
      }
      steps {
        sh "docker context use prod-jd"
        script {
          try{
            sh "docker compose -p proxy-server up -d"
          }catch (Exception e){
            currentBuild.result = "ABORTED"
            error("Failed to update service! Someone should be alerted! =O")
          }
        }
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
