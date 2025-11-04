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
                // Add your real deploy script here
            }
        }

        stage('Trigger Test Container') {
            steps {
                echo "🧪 Running Playwright Tests (NodeJS)..."
                sh """
                    rm -f test_status.txt

                    docker run --rm \
                        -v \${WORKSPACE}:/workspace \
                        -w /workspace \
                        mcr.microsoft.com/playwright:v1.44.0-jammy bash -c "\
                        npm install && \
                        npx playwright install && \
                        npx playwright test --reporter=html \
                        " || echo \$? > test_status.txt

                    if [ ! -f test_status.txt ]; then
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
                echo "📊 Publishing Playwright HTML Report..."
                publishHTML(target: [
                    allowMissing: true,
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
                subject: "❌ UI Test Failed (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: "⚠ Tests failed but deployment completed.\nReport: ${env.BUILD_URL}UI_20Test_20Report"
            )
        }

        success {
            emailext(
                to: "gopalakrishnan93843@gmail.com",
                subject: "✅ UI Test Passed (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: "✅ Deployment and UI tests succeeded!\nReport: ${env.BUILD_URL}UI_20Test_20Report"
            )
        }
    }
}
