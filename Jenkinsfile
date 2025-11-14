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
           🧪 2. Run Playwright Tests (NON-BLOCKING)
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

                        // ⭐ SAFE container create (OPTION-B)
                        sh """
                            docker create --name '${containerName}' \
                              -e GMAIL_USER='${GMAIL_USER}' \
                              -e GMAIL_PASS='${GMAIL_PASS}' \
                              -e AWS_REGION='${AWS_REGION}' \
                              -e AWS_ACCESS_KEY_ID='${AWS_ACCESS_KEY_ID}' \
                              -e AWS_SECRET_ACCESS_KEY='${AWS_SECRET_ACCESS_KEY}' \
                              -e S3_BUCKET='${S3_BUCKET}' \
                              -e TEST_SUITE='${params.TEST_SUITE}' \
                              '${IMAGE_NAME}:latest'
                        """

                        echo "📦 Copying GitHub code into container..."
                        sh "docker cp ${WORKSPACE}/. ${containerName}:/workspace"

                        echo "🔧 Starting container and fixing permissions..."
                        sh "docker start ${containerName}"
                        sh "docker exec ${containerName} chmod +x /workspace/run_tests.sh"

                        echo "🧪 Launching Playwright tests IN BACKGROUND..."

                        // ⭐ NON-BLOCKING execution + AUTO-STOP container
                        sh """
                            docker exec -d ${containerName} bash /workspace/run_tests.sh

                            # Background watcher to STOP container after tests finish
                            (
                                docker exec ${containerName} bash /workspace/run_tests.sh
                                docker stop ${containerName}
                            ) &
                        """

                        echo "➡️ Jenkins continues immediately (tests running in background)"
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

    /* ────────────────────────────────
       🧾 Post Actions
    ───────────────────────────────── */
    post {
        success {
            echo "✅ Pipeline finished successfully — tests running in background."
        }
        failure {
            echo "❌ Pipeline failed — check logs."
        }
    }
}
