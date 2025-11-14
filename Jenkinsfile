pipeline {
    agent any

    parameters {
        choice(name: 'TEST_SUITE', choices: ['Exammaker', 'Examtaker', 'reports', 'all'])
    }

    environment {
        DOCKER_HOST = "tcp://host.docker.internal:2375"
        AWS_REGION = "ap-south-1"
        S3_BUCKET = "playwright-test-reports-gokul"
        IMAGE_NAME = "gokul603/playwright-base"
        CONTAINER_NAME = "pw_runner"
    }

    stages {

        stage('Cleanup') {
            steps {
                sh "docker rm -f ${CONTAINER_NAME} || true"
            }
        }

        stage('Run Playwright Tests') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'gmail-smtp',
                            usernameVariable: 'GMAIL_USER',
                            passwordVariable: 'GMAIL_PASS'
                        ),
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-s3-access']
                    ]) {

                        echo "▶️ Running Playwright Tests: ${params.TEST_SUITE}"

                        sh '''
docker run -d --rm \
  --name pw_runner \
  -v /var/jenkins_home/jobs/playwright-automation-pipeline/workspace:/workspace \
  -w /workspace \
  -e GMAIL_USER="$GMAIL_USER" \
  -e GMAIL_PASS="$GMAIL_PASS" \
  -e AWS_REGION="$AWS_REGION" \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e TEST_SUITE="''' + params.TEST_SUITE + '''" \
  ''' + "${IMAGE_NAME}:latest" + ''' \
  bash run_tests.sh
'''

                        sh "docker logs -f pw_runner"
                        sh "docker wait pw_runner"
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker rm -f pw_runner || true"
        }
        success {
            echo "🎉 Pipeline Completed Successfully"
        }
        failure {
            echo "❌ Pipeline Failed"
        }
    }
}
