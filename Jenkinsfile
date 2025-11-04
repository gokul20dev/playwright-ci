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

        stage('Deploy to Dev (Immediate Deploy)') {
            steps {
                echo "🚀 Deploying to Dev environment..."
            }
        }

        stage('Trigger Test Container') {
            steps {
                echo "🧪 Running Playwright Tests..."

                sh """
                    echo "" > test_status.txt

                    # Start a detached Playwright container
                    docker run --name pwtest -d mcr.microsoft.com/playwright:v1.44.0-jammy tail -f /dev/null

                    # Copy code into container
                    docker cp . pwtest:/workspace

                    # Install & run tests inside the correct folder
                    docker exec pwtest bash -c "cd /workspace/playwright-tests && npm ci && npx playwright install --with-deps && npx playwright test --reporter=html" \
                    || echo "1" > test_status.txt

                    # Copy back the test report to Jenkins
                    docker cp pwtest:/workspace/playwright-tests/playwright-report .

                    # Clean up container
                    docker stop pwtest
                    docker rm pwtest

                    # If no error → success
                    if [ ! -s test_status.txt ]; then
                        echo "0" > test_status.txt
                    fi
                """
            }
        }

        stage('Collect Test Result') {
            steps {
                script {
                    def status = readFile('test_status.txt').trim()
                    if (status != '0') {
                        currentBuild.result = 'UNSTABLE'
                        echo "❌ Tests Failed — Deployment done but needs manual rollback"
                    } else {
                        echo "✅ Tests Passed — Deployment Confirmed"
                    }
                }
            }
        }

        stage('Publish Test Report') {
            steps {
                echo "📊 Publishing Playwright Report..."
                publishHTML(target: [
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'playwright-report',
                    reportFiles: 'index.html',
                    reportName: 'UI Test Report'
                ])
            }
        }
    }

    post {
        unstable {
            emailext(
                to: "gopalakrishnan93843@gmail.com",
                subject: "❌ UI Tests Failed (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: """
⚠ Deployment completed — but UI tests failed.  
View Test Report: ${env.BUILD_URL}HTML_20Report/
"""
            )
        }

        success {
            emailext(
                to: "gopalakrishnan93843@gmail.com",
                subject: "✅ UI Tests Passed (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: """
✅ Deployment succeeded & UI tests passed!  
View Test Report: ${env.BUILD_URL}HTML_20Report/
"""
            )
        }
    }
}
