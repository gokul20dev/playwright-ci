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
         🧪 Stage 1: Run Playwright Tests
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

                        // ✅ Write AWS credentials to Jenkins home so Docker can use it
                        sh '''
                            echo "🔍 Writing temporary AWS credentials file for Docker..."
                            mkdir -p ~/.aws
                            cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
region=${AWS_REGION:-ap-south-1}
EOF
                            echo "✅ Jenkins wrote ~/.aws/credentials"

                            docker run --rm --name pw_test_${TEST_SUITE} \
                              -e GMAIL_USER=$GMAIL_USER \
                              -e GMAIL_PASS=$GMAIL_PASS \
                              -e AWS_REGION=$AWS_REGION \
                              -e S3_BUCKET=$S3_BUCKET \
                              -e TEST_SUITE=$TEST_SUITE \
                              -v ~/.aws:/root/.aws:ro \
                              -v $WORKSPACE:/workspace \
                              -w /workspace \
                              gokul603/playwright-email-tests:latest ./run_tests.sh
                        '''

                        echo "✅ Docker container '${containerName}' completed successfully."
                    }
                }
            }
        }

        /* ────────────────────────────────
         ☁️ Stage 2: Upload Report to S3 (Backup)
        ───────────────────────────────── */
        stage('Upload Report to S3') {
            steps {
                withAWS(credentials: 'aws-s3-access', region: "${AWS_REGION}") {
                    script {
                        def timestamp = new Date().format("yyyy-MM-dd_HH-mm-ss")
                        def s3Path = "${params.TEST_SUITE}/${timestamp}/"
                        def reportUrl = "https://${S3_BUCKET}.s3.${AWS_REGION}.amazonaws.com/${s3Path}index.html"

                        echo "☁️ Uploading report to s3://${S3_BUCKET}/${s3Path} ..."
                        sh "aws s3 cp playwright-report s3://${S3_BUCKET}/${s3Path} --recursive --acl public-read"

                        // Export report link for email
                        env.REPORT_URL = reportUrl
                        echo "🌐 Public report link: ${reportUrl}"
                    }
                }
            }
        }

        /* ────────────────────────────────
         📧 Stage 3: Send Email Notification
        ───────────────────────────────── */
        stage('Send Email Notification') {
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
                        echo "📧 Sending email with S3 report link..."

                        sh '''
                            echo "🔍 Debug: Checking AWS credentials before sending email"
                            echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:0:4}****"
                            echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:0:4}****"

                            export REPORT_URL="${REPORT_URL}"
                            export TEST_SUITE="${TEST_SUITE}"
                            export GMAIL_USER="${GMAIL_USER}"
                            export GMAIL_PASS="${GMAIL_PASS}"
                            export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
                            export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
                            export AWS_REGION="${AWS_REGION}"

                            node send_report.js
                        '''
                    }
                }
            }
        }
    }

    /* ────────────────────────────────
       🧹 Post Cleanup
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

