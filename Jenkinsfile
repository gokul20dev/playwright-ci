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
                echo "🚀 Deploying Application (no wait for tests)"
            }
        }

        stage('Run UI Tests in Docker') {
              
            steps {
                echo "🐳 Running Playwright tests in Docker..."
                sh '''
                    docker run --rm \
                        -v $PWD:/tests \
                        -w /tests \
                        mcr.microsoft.com/playwright:v1.44.0-jammy \
                        /bin/bash -c "npm install && npx playwright install && npx playwright test --reporter=html" \
                        || echo $? > test_status.txt
                        
                    # fallback if exit code not captured
                    if [ ! -f test_status.txt ]; then
                        echo "0" > test_status.txt
                    fi
                '''
            }
        }

        stage('Check Test Result') {
            steps {
                script {
                    def status = readFile('test_status.txt').trim()
                    if (status != '0') {
                        currentBuild.result = 'UNSTABLE'
                        echo "❌ UI Tests Failed — Manual rollback needed"
                    } else {
                        echo "✅ UI Tests Passed"
                    }
                }
            }
        }

        stage('Publish Report') {
            steps {
                publishHTML(target: [
                    allowMissing: true,
                    keepAll: true,
                    reportDir: 'playwright-report',
                    reportFiles: 'index.html',
                    reportName: 'Playwright Report'
                ])
            }
        }
    }

    post {

        unstable {
            emailext(
                subject: "❌ UI Tests Failed - Manual Action (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: "🚨 Tests Failed! Manual rollback required.\nReport: ${env.BUILD_URL}Playwright_20Report",
                to: "gopalakrishnan93843@gmail.com"
            )
        }

        success {
            emailext(
                subject: "✅ UI Tests Passed (${env.JOB_NAME} #${env.BUILD_NUMBER})",
                body: "✅ All UI tests passed!\nReport: ${env.BUILD_URL}Playwright_20Report",
                to: "gopalakrishnan93843@gmail.com"
            )
        }
    }
}
