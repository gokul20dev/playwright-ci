pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        RECEIVER_EMAIL = "gopalakrishnan93843@gmail.com" // ✅ Change your mail here
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

        stage('Trigger UI Tests in Background') {
            steps {
                echo "⚡ Triggering Playwright UI Test Container (not waiting for results)..."

                sh '''
                    echo "🧹 Cleaning any old test containers..."
                    docker rm -f pwtest || true

                    echo "🚀 Launching Background Playwright Test Container..."
                    docker run -d --name pwtest \
                        -v $(pwd):/workspace \
                        -e RECEIVER_EMAIL="${RECEIVER_EMAIL}" \
                        mcr.microsoft.com/playwright:v1.44.0-jammy \
                        bash -c "
                            cd /workspace &&
                            echo '📦 Installing dependencies...' &&
                            npm install &&
                            npx playwright install --with-deps &&
                            echo '▶ Running tests...' &&
                            if npx playwright test --reporter=dot ; then
                                echo '✅ Playwright Tests Passed' | mail -s 'TEST STATUS ✅ PASSED' \$RECEIVER_EMAIL
                            else
                                echo '❌ Playwright Tests Failed' | mail -s 'TEST STATUS ❌ FAILED' \$RECEIVER_EMAIL
                            fi
                        "
                    echo "✅ Test container started successfully. Jenkins is moving on..."
                '''
            }
        }

        stage('Build & Deploy') {
            steps {
                echo "🚀 Build and Deployment will run without waiting for tests!"
                // 👉 Add your deployment steps here
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline finished! UI Tests running separately."
        }
    }
}
