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

        // AWS Config
        AWS_REGION = "ap-south-1"
        S3_BUCKET = "playwright-test-reports-gokul"
    }

    stages {

        /* ────────────────────────────────
         🧪 Stage 1: Run Playwright Tests in Docker
        ───────────────────────────────── */
        stage('Run Playwright Tests in Docker') {
            steps {
                script {
                    def containerName = "pw_test_${params.TEST_SUITE}"

                    // Inject Gmail + AWS credentials securely
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'gmail-smtp',
                            usernameVariable: 'GMAIL_USER',
                            passwordVariable: 'GMAIL_PASS'
                        ),
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-s3-access']
                    ]) {

                        echo "🧹 Cleaning up old container if exists..."
                        sh "docker rm -f ${containerName} || true"

                        echo "🚀 Running Playwright test suite: ${params.TEST_SUITE}"

                        // ✅ Run Docker container — image will auto-run run_tests.sh
                        sh """
                            docker run --rm --name ${containerName} \
                              -e "GMAIL_USER=${GMAIL_USER}" \
                              -e "GMAIL_PASS=${GMAIL_PASS}" \
                              -e "AWS_REGION=${AWS_REGION}" \
                              -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
                              -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
                              -e "S3_BUCKET=${S3_BUCKET}" \
                              -e "TEST_SUITE=${params.TEST_SUITE}" \
                              gokul603/playwright-email-tests:latest
                        """

                        echo "✅ Docker container '${containerName}' completed successfully."
                    }
                }
            }
        }
    }

    /* ────────────────────────────────
       🧹 Post-Cleanup & Notifications
    ───────────────────────────────── */
    post {
        always {
            echo "🧹 Cleaning up leftover containers (if any)..."
            script {
                def containerName = "pw_test_${params.TEST_SUITE}"
                sh "docker rm -f ${containerName} || true"
                echo "🧽 Cleanup done."
            }
        }

        success {
            echo "📬 Email report sent — check your inbox ✅"
        }

        failure {
            echo "❌ Pipeline failed — check console logs for errors"
        }
    }
}
