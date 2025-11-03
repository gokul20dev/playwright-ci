pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "📥 Fetching code from GitHub..."
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "📦 Installing npm packages..."
                sh 'npm install'
                sh 'npx playwright install'
            }
        }

        stage('Run Playwright Tests') {
            steps {
                echo "🧪 Running Playwright Tests..."
                sh 'npx playwright test --reporter=html'
            }
        }

        stage('Publish Report') {
            steps {
                echo "📊 Publishing HTML report..."
                publishHTML(target: [
                    allowMissing: false,
                    keepAll: true,
                    reportDir: 'playwright-report',
                    reportFiles: 'index.html',
                    reportName: 'Playwright Test Report'
                ])
            }
        }

        stage('Deploy to Dev') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo "🚀 Deploying to Dev because all tests passed ✅"
                // TODO: Add deployment commands later
            }
        }
    }

    post {
        failure {
            echo "❌ Tests Failed — Deployment Aborted"
        }
    }
}
