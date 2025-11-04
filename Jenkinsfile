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

                // ✅ FIXED TEST EXECUTION STAGE
                sh '''
                    set -e

                    echo "🧹 Removing old test container if exists..."
                    docker rm -f pwtest || true

                    echo "🐳 Starting Playwright Test Container..."
                    docker run --name pwtest -d mcr.microsoft.com/playwright:v1.44.0-jammy tail -f /dev/null

                    echo "📂 Copying test files..."
                    docker exec pwtest mkdir -p /workspace
                    docker cp playwright-tests/package.json pwtest:/workspace/
                    docker cp playwright-tests/playwright.config.ts pwtest:/workspace/
                    docker cp playwright-tests/tests pwtest:/workspace/tests

                    echo "🛠 Installing Dependencies & Running Tests..."
                    docker exec pwtest bash -c "
                        cd /workspace &&
                        npm install &&
                        npx playwright install --with-deps &&
                        npx playwright test --reporter=html
                    "
                    TEST_EXIT=$?

                    echo "📁 Copying HTML report back to Jenkins..."
                    rm -rf test-report || true
                    mkdir -p test-report
                    docker cp pwtest:/workspace/playwright-report test-report/ || true

                    echo "🧽 Cleaning test container..."
                    docker rm -f pwtest || true

                    exit $TEST_EXIT
                '''
            }
        }

        stage('Collect Test Result') {
            steps {
                script {
                    if (currentBuild.currentResult == "FAILURE") {
                        echo "❌ Tests Failed — Marking Build UNSTABLE"
                        currentBuild.result = "UNSTABLE"
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
                    allowMissing       : true,
                    alwaysLinkToLastBuild: true,
                    keepAll           : true,
                    reportDir         : 'test-report/playwright-report',
                    reportFiles       : 'index.html',
                    reportName        : 'UI Test Report'
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
Report: ${env.BUILD_URL}HTML_20Report/
"""
            )
        }

        success {
            emailext(
                to: "gopalakrishnan93843@gmail.com",
                subject: "✅ UI Tests Passed (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: """
✅ Deployment succeeded & UI tests passed!  
Report: ${env.BUILD_URL}HTML_20Report/
"""
            )
        }
    }
}
