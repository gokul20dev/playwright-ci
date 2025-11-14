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
           📥 1. Checkout Full GitHub Repo
        ───────────────────────────────── */
        stage('Checkout Code') {
            steps {
                echo "📥 Pulling latest code from GitHub..."
                checkout scm
                sh "ls -la"
            }
        }

        /* ────────────────────────────────
           🧪 2. Run Playwright Tests in Container
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

                        // 1️⃣ Create container (does NOT start tests)
                        sh """
                            docker create --name ${containerName} \
                              -e "GMAIL_USER=${GMAIL_USER}" \
                              -e "GMAIL_PASS=${GMAIL_PASS}" \
                              -e "AWS_REGION=${AWS_REGION}" \
                              -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
                              -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
                              -e "S3_BUCKET=${S3_BUCKET}" \
                              -e "TEST_SUITE=${params.TEST_SUITE}" \
                              ${IMAGE_NAME}:latest
                        """

                        echo "📦 Copying latest GitHub code into container..."

                        // 2️⃣ Copy GitHub code into /workspace inside container
                        sh """
                            docker cp ${WORKSPACE}/. ${containerName}:/workspace
                        """

                        echo "🔧 Fixing permissions..."
                        // 3️⃣ Make run_tests.sh executable
                        sh """
                            docker start ${containerName}
                            docker exec ${containerName} chmod +x /workspace/run_tests.sh
                        """

                        echo "🧪 Starting Playwright tests..."
                        // 4️⃣ Run tests inside container
                        sh """
                            docker exec ${containerName} /workspace/run_tests.sh
                        """

                        echo "🧹 Stopping container after test completion..."
                        // 5️⃣ Stop container after tests complete
                        sh """
                            docker stop ${containerName}
                        """
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
                sleep(time: 2, unit: 'SECONDS')
            }
        }

        /* ────────────────────────────────
           🚀 4. Deploy (Dummy)
        ───────────────────────────────── */
        stage('Deploy') {
            steps {
                echo "🚀 Dummy deploy..."
                sleep(time: 2, unit: 'SECONDS')
            }
        }
    }

    /* ────────────────────────────────
       📩 Post Actions
    ───────────────────────────────── */
    post {
        success {
            echo "✅ Pipeline completed successfully"
        }
        failure {
            echo "❌ Pipeline failed — check logs"
        }
    }
}
