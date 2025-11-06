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
                script {
                    def containers = ["pw_test_1", "pw_test_2"]

                    withCredentials([usernamePassword(
                        credentialsId: 'gmail-smtp',
                        usernameVariable: 'GMAIL_USER',
                        passwordVariable: 'GMAIL_PASS'
                    )]) {

                        containers.each { name ->
                            sh """
                                docker rm -f ${name} || true
                                docker run -d --name ${name} \
                                  -e GMAIL_USER="${GMAIL_USER}" \
                                  -e GMAIL_PASS="${GMAIL_PASS}" \
                                  -v ${env.WORKSPACE}:/workspace \
                                  gokul603/playwright-email-tests:latest
                            """
                        }
                    }
                }
            }
        }

        stage('Build & Deploy') {
            steps {
                echo "🚀 Deploying App while tests run..."
            }
        }
    }

    post {
        always {
            echo "📬 Test report email should be received ✅"
        }
    }
}
