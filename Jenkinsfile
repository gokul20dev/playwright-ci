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

        /* ────────────────────────────────
           🔄 0. Cleanup Old Containers
        ───────────────────────────────── */
        stage('Pre-clean Old Containers') {
            steps {
                script {
                    def containerName = "pw_test_${params.TEST_SUITE}"
                    echo "🧹 Removing previous container if exists..."
                    sh "docker rm -f ${containerName} || true"
                }
            }
        }

        /* ────────────────────────────────
           📥 1. Checkout Code
        ───────────────────────────────── */
        stage('Checkout Code') {
            steps {
                echo "📥 Pulling latest code from GitHub..."
                checkout scm
                sh "ls -la"
            }
        }

        /* ────────────────────────────────
           🧪 2. Run Playwright Tests
        ───────────────────────────────── */
        stage('Run Playwright Tests') {
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

                        echo "🚀 Creating container for test suite: ${params.TEST_SUITE}"

                        sh """
                            docker create \
                              -v /var/run/docker.sock:/var/run/docker.sock \
                              --name '${containerName}' \
                              -e GMAIL_USER='${GMAIL_USER}' \
                              -e GMAIL_PASS='${GMAIL_PASS}' \
                              -e AWS_REGION='${AWS_REGION}' \
                              -e AWS_ACCESS_KEY_ID='${AWS_ACCESS_KEY_ID}' \
                              -e AWS_SECRET_ACCESS_KEY='${AWS_SECRET_ACCESS_KEY}' \
                              -e S3_BUCKET='${S3_BUCKET}' \
                              -e TEST_SUITE='${params.TEST_SUITE}' \
                              '${IMAGE_NAME}:latest'
                        """

                        echo "📦 Syncing changed GitHub files into container..."
                        sh """
                            docker cp ${WORKSPACE}/tests ${containerName}:/workspace/
                            docker cp ${WORKSPACE}/playwright.config.ts ${containerName}:/workspace/
                            docker cp ${WORKSPACE}/send_report.js ${containerName}:/workspace/
                            docker cp ${WORKSPACE}/run_tests.sh ${containerName}:/workspace/
                            docker cp ${WORKSPACE}/package.json ${containerName}:/workspace/
                            docker cp ${WORKSPACE}/package-lock.json ${containerName}:/workspace/
                        """

                        echo "📦 Installing updated dependencies..."
                        sh "docker exec ${containerName} npm install --quiet || true"

                        echo "🔧 Starting container..."
                        sh "docker start ${containerName}"

                        echo "🔧 Ensuring permissions..."
                        sh "docker exec ${containerName} chmod +x /workspace/run_tests.sh"

                        echo "🧪 Running Playwright tests in background..."
                        sh "docker exec -d ${containerName} bash /workspace/run_tests.sh"

                        echo "✔ Test execution started — container will auto-stop when done."
                    }
                }
            }
        }

        /* ────────────────────────────────
           🏗️ 3. Build (Dummy)
        ───────────────────────────────── */
        stage('Build') {
            steps {
                echo "🏗️ Dummy build..."
                sleep 2
            }
        }

        /* ────────────────────────────────
           🚀 4. Deploy (Dummy)
        ───────────────────────────────── */
        stage('Deploy') {
            steps {
                echo "🚀 Dummy deploy..."
                sleep 2
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline finished successfully."
        }
        failure {
            echo "❌ Pipeline failed — check logs."
        }
    }
}
