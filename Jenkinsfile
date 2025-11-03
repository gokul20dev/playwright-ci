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
                // Add deployment script here later
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

                        // Capture status manually
                        sh '''
                            npx playwright test --reporter=html
                            echo "UI_TEST_STATUS=$?" > test_status.txt
                        '''
                    }
                }
            }
        }

        stage('Check Test Result') {
            steps {
                script {
                    def status = readFile('test_status.txt').trim().replace('UI_TEST_STATUS=','')

                    if (status != '0') {
                        echo "⚠️ Tests Failed — Marking build as UNSTABLE"
                        currentBuild.result = 'UNSTABLE'
                    } else {
                        echo "✅ Tests Passed"
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
        unstable {
            emailext(
                subject: "❌ UI Tests Failed - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
Hi Team,

🚨 UI Tests have FAILED but deployment continued.

Build: ${env.BUILD_NUMBER}
Job: ${env.JOB_NAME}

View Report:
${env.BUILD_URL}Playwright_20Test_20Report
""",
                to: "gopalakrishnan93843@gmail.com"
            )
        }

        always {
            echo "✅ Build Completed ✅"
        }
    }
}
