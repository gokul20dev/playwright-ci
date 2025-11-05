pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
    }

    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Pulling code from GitHub..."
                checkout scm
            }
        }

        stage('Trigger UI Tests in Docker') {
            steps {
                echo "🧪 Running Playwright tests in container..."

                sh '''
                    set -e
                    
                    echo "🧹 Cleaning old containers..."
                    docker rm -f pwtest || true

                    echo "🐳 Starting Playwright test container..."
                    docker run --name pwtest -d mcr.microsoft.com/playwright:v1.44.0-jammy tail -f /dev/null

                    echo "📂 Copying project files to container..."
                    docker exec pwtest mkdir -p /workspace
                    docker cp package.json pwtest:/workspace/
                    docker cp package-lock.json pwtest:/workspace/
                    docker cp playwright.config.ts pwtest:/workspace/
                    docker cp tests pwtest:/workspace/tests

                    echo "📦 Installing dependencies..."
                    docker exec pwtest bash -c "
                        cd /workspace &&
                        npm install &&
                        npx playwright install --with-deps
                    "

                    echo "▶ Running tests and generating HTML reports..."
                    docker exec pwtest bash -c "
                        cd /workspace &&
                        npx playwright test --reporter=html
                    "
                    TEST_EXIT=$?

                    echo "📤 Copy report to Jenkins workspace..."
                    rm -rf test-report || true
                    mkdir -p test-report
                    docker cp pwtest:/workspace/playwright-report test-report/

                    echo "🧽 Cleaning test container..."
                    docker rm -f pwtest || true

                    exit $TEST_EXIT
                '''
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo "📊 Publishing Playwright HTML Report..."
                publishHTML(target: [
                    reportDir: 'test-report/playwright-report',
                    reportFiles: 'index.html',
                    reportName: 'UI Automation Report',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: true
                ])
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline completed (check report above 👆)"
        }
        failure {
            echo "❌ UI tests failed"
        }
    }
}
