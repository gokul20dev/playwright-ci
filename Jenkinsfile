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

        // ✅ Correct image
        IMAGE_NAME = "gokul603/playwright-email-tests"
    }

    stages {

        stage('Cleanup') {
            steps {
                script {
                    sh "docker rm -f pw_runner || true"
                }
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

                        sh """
                            docker run -d --rm --pull=never \
                              --name pw_runner \
                              -v ${WORKSPACE}:/workspace \
                              -w /workspace \
                              -e TEST_SUITE=${params.TEST_SUITE} \
                              -e GMAIL_USER=${GMAIL_USER} \
                              -e GMAIL_PASS=${GMAIL_PASS} \
                              -e AWS_REGION=${AWS_REGION} \
                              -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
                              -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
                              -e S3_BUCKET=${S3_BUCKET} \
                              ${IMAGE_NAME}:latest \
                              bash run_tests.sh
                        """

                        echo "🚀 Container started successfully."
                    }
                }
            }
        }

        stage('Build') {
            steps { echo "Skipping build… (dummy)" }
        }

        stage('Deploy') {
            steps { echo "Skipping deploy… (dummy)" }
        }
    }

    post {
        success {
            echo "✅ Pipeline Completed Successfully"
        }
        failure {
            echo "❌ Pipeline Failed"
            sh "docker rm -f pw_runner || true"
        }
    }
}

