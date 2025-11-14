pipeline {
    agent any

    parameters {
        choice(
            name: 'TEST_SUITE',
            choices: ['Exammaker', 'Examtaker', 'reports', 'all'],
            description: 'Select Playwright test suite'
        )
    }

    environment {
        DOCKER_HOST = "tcp://host.docker.internal:2375"
        AWS_REGION = "ap-south-1"
        S3_BUCKET = "playwright-test-reports-gokul"
        IMAGE_NAME = "gokul603/playwright-base"
    }

    stages {

        stage('Cleanup Old Containers') {
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
                        [$class: 'AmazonWebServicesCredentialsBinding',
                         credentialsId: 'aws-s3-access']
                    ]) {

                        echo "▶️ Running Playwright Tests: ${params.TEST_SUITE}"

                        sh """
                            docker run -d --rm \
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
                    }
                }
            }
        }

        stage('Build') {
            steps {
                echo "Dummy Build stage"
            }
        }

        stage('Deploy') {
            steps {
                echo "Dummy Deploy stage"
            }
        }
    }

    post {
        success {
            echo "Pipeline Finished Successfully ✔"
        }
        failure {
            echo "Pipeline Failed ❌ — check logs!"
        }
    }
}
