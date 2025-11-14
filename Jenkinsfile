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

        /* ───────────────────────────
           🧹 CLEANUP
        ─────────────────────────── */
        stage('Cleanup') {
            steps {
                script {
                    sh "docker rm -f pw_runner || true"
                }
            }
        }

        /* ───────────────────────────
           🧪 RUN TESTS
        ─────────────────────────── */
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
                              --env TEST_SUITE=${params.TEST_SUITE} \
                              --env GMAIL_USER=${GMAIL_USER} \
                              --env GMAIL_PASS="${GMAIL_PASS}" \
                              --env AWS_REGION=${AWS_REGION} \
                              --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
                              --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
                              --env S3_BUCKET=${S3_BUCKET} \
                              ${IMAGE_NAME}:latest \
                              bash run_tests.sh
                        """

                        echo "🚀 Container started successfully."
                    }
                }
            }
        }

        /* ───────────────────────────
           🏗️ BUILD (DUMMY)
        ─────────────────────────── */
        stage('Build') {
            steps { 
                echo "🏗️ Dummy Build Stage" 
            }
        }

        /* ───────────────────────────
           🚀 DEPLOY (DUMMY)
        ─────────────────────────── */
        stage('Deploy') {
            steps { 
                echo "🚀 Dummy Deploy Stage" 
            }
        }
    }

    /* ───────────────────────────
       ✔ POST ACTIONS
    ─────────────────────────── */
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
