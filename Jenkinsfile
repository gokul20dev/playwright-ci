pipeline {
    agent any

    parameters {
        choice(name: 'TEST_SUITE', choices: [
            'Exammaker',
            'Examtaker',
            'reports',
            'all'
        ], description: 'Select which Playwright test suite to run')
    }

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        DOCKER_HOST = "tcp://host.docker.internal:2375"
    }

    stages {
        stage('Trigger UI Tests in Docker') {
            steps {
                script {
                    def containerName = "pw_test_${params.TEST_SUITE}"

                    withCredentials([usernamePassword(
                        credentialsId: 'gmail-smtp',
                        usernameVariable: 'GMAIL_USER',
                        passwordVariable: 'GMAIL_PASS'
                    )]) {
                        // Clean up previous container if exists
                        sh "docker rm -f ${containerName} || true"

                        // Run Docker container with selected test suite
                        sh """
                            docker run --rm --name ${containerName} \\
                              -e GMAIL_USER="${GMAIL_USER}" \\
                              -e GMAIL_PASS="${GMAIL_PASS}" \\
                              -e TEST_SUITE="${params.TEST_SUITE}" \\
                              gokul603/playwright-email-tests:latest
                        """
                    }
                }
            }
        }

        stage('Deploy (Placeholder)') {
            steps {
                echo "🚀 Deployment step — optional"
            }
        }
    }

    post {
        always {
            echo "📬 Email report sent — check your inbox ✅"
        }
    }
}
