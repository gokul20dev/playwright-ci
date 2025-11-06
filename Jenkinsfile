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
                echo "⚡ Starting Playwright Test Containers asynchronously..."
                script {
                    // List of test containers
                    def containers = ["playwright_test_1", "playwright_test_2"]

                    containers.each { name ->
                        sh """
                            # Remove old container if exists
                            docker rm -f ${name} || true

                            # Run container in detached mode (-d) so Jenkins doesn't wait
                            docker run -d --name ${name} \
                                -v "/var/jenkins_home/jobs/playwright-automation-pipeline/workspace:/workspace" \
                                -w /workspace \
                                gokul603/playwright-email-tests:latest
                        """
                        echo "✅ Container ${name} triggered successfully!"
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
