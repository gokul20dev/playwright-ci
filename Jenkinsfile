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

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Starting Playwright Test Containers asynchronously..."
                script {
                    // List of test containers (you can add more)
                    def containers = ["playwright_test_1", "playwright_test_2"]

                    containers.each { name ->
                        sh """
                            docker run -d --name ${name} \
                            -v "${WORKSPACE}":/workspace \
                            -w /workspace \
                            gokul603/playwright-email-tests:latest \
                            npx playwright test ./tests --reporter=list
                        """
                        echo "✅ Container ${name} started in background!"
                    }

                    // Save container names for post stage
                    env.PLAYWRIGHT_CONTAINERS = containers.join(",")
                }
            }
        }

        stage('Build & Deploy') {
            steps {
                echo "🚀 Building & Deploying Application..."
                // Your actual deploy commands go here
            }
        }
    }

    post {
        always {
            script {
                echo "📝 Collecting Playwright test results..."

                // Split the container names
                def containers = env.PLAYWRIGHT_CONTAINERS.split(",")

                containers.each { name ->
                    // Wait for container to finish
                    sh "docker wait ${name}"

                    // Get exit code
                    def status = sh(script: "docker inspect ${name} --format='{{.State.ExitCode}}'", returnStdout: true).trim()

                    // Save logs
                    sh "docker logs ${name} > ${WORKSPACE}/${name}_logs.txt"

                    // Remove container
                    sh "docker rm ${name}"

                    echo "📄 Logs saved to ${WORKSPACE}/${name}_logs.txt"
                    echo "Container ${name} finished with exit code ${status}"
                }

                // Email notification
                mail to: "${RECEIVER_EMAIL}",
                     subject: "Pipeline & Playwright Test Results",
                     body: """Hi,

Pipeline has completed.

Playwright test containers: ${containers.join(", ")}
You can check full logs in the workspace.

Regards,
CI/CD Pipeline"""
                echo "✅ Email sent!"
            }
        }
    }
}
