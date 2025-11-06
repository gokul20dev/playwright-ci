pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Starting Playwright Test Containers..."
                script {
                    // List of test containers
                    def containers = ["playwright_test_1", "playwright_test_2"]

                    containers.each { name ->
                        sh """
                            # Remove old container if exists
                             docker rm -f ${name} || true

                            # Run container and remove automatically after tests
                             docker run --rm --name ${name} \
                                -v "${WORKSPACE}":/workspace \
                                -w /workspace \
                                gokul603/playwright-email-tests:latest
                        """
                        echo "✅ Container ${name} ran successfully!"
                    }
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
}
 
