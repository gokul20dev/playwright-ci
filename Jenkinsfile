pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        DOCKER_HOST = "tcp://host.docker.internal:2375"
    }

    stages {

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Triggering Playwright Tests in background.."

                script {
                    def containers = ["playwright_test_1", "playwright_test_2"]

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'gmail-smtp',
                            usernameVariable: 'GMAIL_USER',
                            passwordVariable: 'GMAIL_PASS'
                        )
                    ]) {

                        containers.each { name ->
                            sh """
                                docker rm -f ${name} || true
                                docker run -d --name ${name} \
                                  -e GMAIL_USER="${GMAIL_USER}" \
                                  -e GMAIL_PASS="${GMAIL_PASS}" \
                                  -v ${env.WORKSPACE}:/workspace \
                                  -w /workspace \
                                  gokul603/playwright-email-tests:latest \
                                  /workspace/run_tests.sh
                            """
                            echo "✅ ${name} started ✅"
                        }
                    }
                }
            }
        }

        stage('Build & Deploy') {
            steps {
                echo "🚀 Continue Build & Deploy while tests run..."
            }
        }
    }

    post {
        always {
            echo "📧 UI Test Emails sent (each container handles its own email)"
        }
    }
}
