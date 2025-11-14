pipeline {
    agent any

    parameters {
        choice(
            name: 'TEST_SUITE',
            choices: ['Exammaker', 'Examtaker', 'reports', 'all'],
            description: 'Select which Playwright test suite to run'
        )
    }

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"

        DOCKER_HOST = "tcp://host.docker.internal:2375"

        AWS_REGION = "ap-south-1"
        S3_BUCKET = "playwright-test-reports-gokul"
        IMAGE_NAME = "gokul603/playwright-email-tests"
    }

    stages {

        stage('Pre-clean Old Containers') {
            steps {
                script {
                    def containerName = "pw_test_${params.TEST_SUITE}"
                    echo "🧹 Removing previous container..."
                    sh "docker rm -f ${containerName} || true"
                }
            }
        }

        stage('Run Playwright Tests in Docker') {
            steps {
                script {
                    def containerName = "pw_test_${params.TEST_SUITE}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'gmail-smtp',
                            usernameVariable: 'GMAIL_USER',
                            passwordVariable: 'GMAIL_PASS'
                        ),
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-s3-access']
                    ]) {

                        echo "🚀 Running Playwright test suite: ${params.TEST_SUITE}"

                        sh """
                            docker run -d --rm \
                              --name ${containerName} \
                              -v ${WORKSPACE}:/workspace \
                              -w /workspace \
                              -e "GMAIL_USER=${GMAIL_USER}" \
                              -e "GMAIL_PASS=${GMAIL_PASS}" \
                              -e "AWS_REGION=${AWS_REGION}" \
                              -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
                              -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
                              -e "S3_BUCKET=${S3_BUCKET}" \
                              -e "TEST_SUITE=${params.TEST_SUITE}" \
                              ${IMAGE_NAME}:latest \
                              bash run_tests.sh
                        """

                        echo "✅ Container '${containerName}' started successfully."
                    }
                }
            }
        }

        stage('Build') {
            steps {
                echo "🏗️ This is a dummy Build stage — no real build."
                sleep(time: 2, unit: 'SECONDS')
            }
        }

        stage('Deploy') {
            steps {
                echo "🚀 Dummy Deploy stage."
                sleep(time: 2, unit: 'SECONDS')
            }
        }
    }

    post {
        success {
            echo "📬 CI/CD pipeline completed successfully"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}
