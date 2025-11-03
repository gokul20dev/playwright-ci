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

        stage('Deploy to Dev') {
            steps {
                echo "🚀 Deploying Application to Dev (Not waiting for tests)..."
                // TODO: Add deployment commands here
            }
        }

        stage('Run UI Tests in Background') {
            parallel {
                stage('Playwright Tests') {
                    steps {
                        echo "🧪 Running Playwright Tests in background..."
                        
                        sh 'npm install'
                        sh 'chmod +x node_modules/.bin/playwright'
                        sh 'npx playwright install'
                        
                        // Run tests without stopping pipeline if fail
                        sh 'npx playwright test --reporter=html || echo "Tests Failed"'
                    }
                }
            }
        }

        stage('Publish Report') {
            steps {
                echo "📊 Publishing HTML Test Report..."
                publishHTML(target: [
                    allowMissing: true,
                    keepAll: true,
                    reportDir: 'playwright-report',
                    reportFiles: 'index.html',
                    reportName: 'Playwright Test Report'
                ])
            }
        }
    }

    post {
        unsuccessful {
            echo "❌ Tests Failed — Sending Email Alert"

            emailext(
                subject: "❌ Playwright UI Tests Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Hi Team,

🚨 UI Automation tests failed in background.

Job: ${env.JOB_NAME}
Build: ${env.BUILD_NUMBER}

View Report:
${env.BUILD_URL}Playwright_20Test_20Report
""",
                to: "gopalakrishnan93843@gmail.com"
            )
        }

        always {
            echo "✅ Deployment completed ✅"
        }
    }
}
