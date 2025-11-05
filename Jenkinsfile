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
                // Put your deploy commands here
            }
        }

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Running Playwright Test Container..."

                // Run the container
                script {
                    def status = sh(script: """
                        docker run --rm \
                        -v "${WORKSPACE}":/workspace \
                        -w /workspace \
                        gokul603/playwright-email-tests:latest
                    """, returnStatus: true)

                    // Store status for email
                    currentBuild.description = status == 0 ? "Tests Passed ✅" : "Tests Failed ❌"
                }
            }
        }
    }

    post {
        always {
            // Send email using Jenkins mail step
            mail to: "${RECEIVER_EMAIL}",
                 subject: "Playwright Test Results: ${currentBuild.description}",
                 body: "Hi,\n\nYour Playwright tests have finished.\nStatus: ${currentBuild.description}\n\nRegards,\nCI/CD Pipeline"
            echo "✅ Pipeline finished! Email sent."
        }
    }
}
