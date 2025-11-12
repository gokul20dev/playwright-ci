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
        IMAGE_NAME = "gokul603/playwright-email-tests"
    }

    stages {

        /* ────────────────────────────────
         🧪 Stage 1: Run Playwright Tests
        ───────────────────────────────── */
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

                        echo "🧹 Cleaning up old container if exists..."
                        sh "docker rm -f ${containerName} || true"

                        echo "🚀 Running Playwright test suite: ${params.TEST_SUITE}"

                        // ✅ Run Docker container — image auto-runs run_tests.sh
                        sh """
                            docker run -d --name ${containerName} \
                              -e "GMAIL_USER=${GMAIL_USER}" \
                              -e "GMAIL_PASS=${GMAIL_PASS}" \
                              -e "AWS_REGION=${AWS_REGION}" \
                              -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
                              -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
                              -e "S3_BUCKET=${S3_BUCKET}" \
                              -e "TEST_SUITE=${params.TEST_SUITE}" \
                              ${IMAGE_NAME}:latest
                        """

                        echo "✅ Playwright tests completed for suite '${params.TEST_SUITE}'."
                    }
                }
            }
        }

        /* ────────────────────────────────
         🏗️ Stage 2: Build (Dummy)
        ───────────────────────────────── */
        stage('Build') {
            steps {
                echo "🏗️ This is a dummy Build stage — no actual commands."
                echo "✅ Simulating build success..."
                sleep(time: 2, unit: 'SECONDS')
            }
        }

        /* ────────────────────────────────
         🚀 Stage 3: Deploy (Dummy)
        ───────────────────────────────── */
        stage('Deploy') {
            steps {
                echo "🚀 This is a dummy Deploy stage — no actual commands."
                echo "✅ Simulating deployment success..."
                sleep(time: 2, unit: 'SECONDS')
            }
        }
    }

    /* ────────────────────────────────
       🧹 Post Actions
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
            echo "📬 CI/CD pipeline ran through all stages successfully ✅"
        }

        failure {
            echo "❌ Pipeline failed — check console logs for details"
        }
    }
}
