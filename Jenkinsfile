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
                echo "📥 Fetching code from GitHub..."
                checkout scm
            }
        }

        stage('Deploy to Dev') {
            steps {
                echo "🚀 Deploying Application (without waiting for tests)..."
            }
        }

        stage('Run UI Tests in Background') {
            steps {
                echo "🧪 Running Playwright tests in background..."
                sh '''
                    npm install
                    chmod +x node_modules/.bin/playwright
                    npx playwright install

                    echo "⏳ Simulating long-running UI tests"
                    sleep 300
                    # Run tests and capture logs
                    npx playwright test --reporter=html > test_output.log 2>&1 || true
                    TEST_EXIT_CODE=$?

                    # Detect failures even if Playwright exits as success
                    if grep -qi "No tests found" test_output.log || grep -qi "ReferenceError" test_output.log; then
                        TEST_EXIT_CODE=1
                    fi

                    echo "UI_TEST_STATUS=$TEST_EXIT_CODE" > test_status.txt
                '''
            }
        }

        stage('Check Test Result') {
            steps {
                script {
                    def status = readFile('test_status.txt').trim().replace('UI_TEST_STATUS=','')
                    if (status != '0') {
                        currentBuild.result = 'UNSTABLE'
                        echo "❌ Tests Failed — Marking build UNSTABLE"
                    } else {
                        echo "✅ Tests Passed"
                    }
                }
            }
        }

        stage('Publish Report') {
            steps {
                echo "📊 Publishing HTML Report"
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
                subject: "❌ UI Tests Failed — Manual Action Required (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: """
🚨 UI Tests Failed!

🔹 Job: ${env.JOB_NAME}
🔹 Build: ${env.BUILD_NUMBER}

✅ Deployment already done
⚠️ Manual rollback required

HTML Report:
${env.BUILD_URL}Playwright_20Test_20Report
""",
                to: "gopalakrishnan93843@gmail.com"
            )
        }

        success {
            emailext(
                subject: "✅ UI Tests Passed — ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
✅ All UI tests passed successfully!

HTML Report:
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
