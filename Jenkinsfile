pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        RECEIVER_EMAIL = "gopalakrishnan93843@gmail.com"
        PLAYWRIGHT_CONTAINER_NAME = "playwright_tests"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Triggering Playwright Test Container in background..."
                script {
                    // Run container in detached mode
                    sh """
                        docker run -d --name ${PLAYWRIGHT_CONTAINER_NAME} \
                        -v "${WORKSPACE}":/workspace \
                        -w /workspace \
                        gokul603/playwright-email-tests:latest \
                        npx playwright test tests/ --reporter=list
                    """
                    echo "✅ Playwright tests started in background!"
                }
            }
        }

        stage('Build & Deploy') {
            steps {
                echo "🚀 Building & Deploying Application..."
                // Add your actual deploy commands here
            }
        }

        stage('Collect UI Test Results') {
            steps {
                echo "📝 Checking Playwright test results..."
                script {
                    // Wait for the container to finish
                    sh "docker wait ${PLAYWRIGHT_CONTAINER_NAME}"

                    // Get the exit code of the test run
                    def status = sh(script: "docker inspect ${PLAYWRIGHT_CONTAINER_NAME} --format='{{.State.ExitCode}}'", returnStdout: true).trim()

                    // Get the test logs
                    sh "docker logs ${PLAYWRIGHT_CONTAINER_NAME} > playwright_test_logs.txt"

                    // Remove the container
                    sh "docker rm ${PLAYWRIGHT_CONTAINER_NAME}"

                    // Store test status
                    currentBuild.description = status == "0" ? "Tests Passed ✅" : "Tests Failed ❌"
                }
            }
        }
    }

    post {
        always {
            echo "📧 Sending email with test results..."
            mail to: "${RECEIVER_EMAIL}",
                 subject: "Pipeline & Playwright Test Results: ${currentBuild.description}",
                 body: """Hi,

Pipeline has completed.

Playwright test status: ${currentBuild.description}
You can check full logs in the workspace: ${WORKSPACE}/playwright_test_logs.txt

Regards,
CI/CD Pipeline"""
            echo "✅ Email sent!"
        }
    }
}
