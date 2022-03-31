pipeline {
  agent {
    node {
      label "worker-one"
    }
  }
  parameters {
    booleanParam(name: "IS_TESTING", defaultValue: "true", description: "Set to false to skip testing, default true!")
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
        script {
          if (params.IS_TESTING) {
            echo "We should perform some health checks!"
          }
        }
      } 
    }   
    stage("Upstream to ECR") {
      steps {
        upstreamToECR()
      }
    }
    stage("Fetch Environment Variables"){
      steps {
        sh "aws lambda invoke --function-name getProxyServerEnv env --profile $AWS_PROFILE"
        createEnvFile()
      }
    }
    stage("Deploy to ECS"){
      steps {
        sh "docker context use prod-jd"
        script {
          try{
            sh "docker compose -p $DOCKER_IMAGE-jd --env-file service.env up -d"
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
      script {
        sh "docker context use default"
        sh "rm -rf ./*"
        sh "docker image prune -af"
      }
    }
  }
}

def createEnvFile() {
  def env = sh(returnStdout: true, script: """cat ./env | jq '.["body"]'""").trim()
  env = sh(returnStdout: true, script: """echo ${env} | base64 --decode""").trim()
  writeFile file: 'service.env', text: env
}

def upstreamToECR() {
  if (params.IS_DEPLOYING) {
    sh "cp $DOCKER_IMAGE-microservice/target/*.jar ."
    sh "docker context use default"
    sh 'aws ecr get-login-password --region $ECR_REGION --profile joshua | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com'
    sh "docker build -t ${DOCKER_IMAGE} ."
    sh 'docker tag $DOCKER_IMAGE:latest $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:$COMMIT_HASH'
    sh 'docker tag $DOCKER_IMAGE:latest $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:latest'
    sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:$COMMIT_HASH'
    sh 'docker push $AWS_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com/$DOCKER_IMAGE-jd:latest'
  }
}
