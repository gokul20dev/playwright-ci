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

                    containers.each { name ->
                        sh """
                            docker rm -f ${name} || true
                            docker run -d --name ${name} \
                              -v /var/jenkins_home/jobs/playwright-automation-pipeline/workspace:/workspace \
                              -w /workspace \
                              gokul603/playwright-email-tests:latest bash /workspace/run_tests.sh
                        """
                        echo "✅ ${name} started ✅"
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
}
