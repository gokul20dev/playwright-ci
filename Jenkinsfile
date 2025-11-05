pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        RECEIVER_EMAIL = "gopalakrishnan93843@gmail.com"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Build & Deploy') {
            steps {
                echo "🚀 Building & Deploying Application..."
                // Add your actual deploy commands here
            }
        }

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Running Playwright Test Container..."

                script {
                    // Run the container for Playwright tests
                    def status = sh(script: """
                        docker run --rm \
                        -v "${WORKSPACE}":/workspace \
                        -w /workspace \
                        gokul603/playwright-email-tests:latest \
                        npx playwright test tests/
                    """, returnStatus: true)

                    // Store test status
                    currentBuild.description = status == 0 ? "Tests Passed ✅" : "Tests Failed ❌"
                }
            }
        }
    }

    post {
        always {
            echo "📧 Sending email with test results..."

            // Use Jenkins SMTP (configured in Manage Jenkins → Configure System)
            mail to: "${RECEIVER_EMAIL}",
                 subject: "Playwright Test Results: ${currentBuild.description}",
                 body: """Hi,

Your Playwright tests have finished.
Status: ${currentBuild.description}

Regards,
CI/CD Pipeline"""

            echo "✅ Pipeline finished! Email sent."
        }
    }
}
