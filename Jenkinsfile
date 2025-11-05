pipeline {
    agent any

    environment {
        NODE_HOME = tool name: 'nodejs', type: 'nodejs'
        PATH = "${NODE_HOME}/bin:${env.PATH}"
        RECEIVER_EMAIL = "gopalakrishnan93843@gmail.com"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Checking out source code..."
                checkout scm
                sh "ls -lah ${WORKSPACE}"
            }
        }

        stage('Trigger UI Tests') {
            steps {
                echo "⚡ Running Playwright Tests inside Docker..."

                sh """
                    echo "🧹 Removing old container..."
                    docker rm -f pwtest || true

                    echo "🚀 Running Playwright test container..."
                    docker run --name pwtest \
                        -v "${WORKSPACE}":/workspace \
                        -w /workspace \
                        -e RECEIVER_EMAIL="${RECEIVER_EMAIL}" \
                        mcr.microsoft.com/playwright:v1.44.0-jammy \
                        bash -c '
                            set -e
                            export DEBIAN_FRONTEND=noninteractive

                            apt-get update >/dev/null
                            apt-get install -y mailutils postfix >/dev/null 2>&1

                            service postfix start

                            if [ ! -f package.json ]; then
                                echo "❌ No package.json found! UI Repo Missing!" | mail -s "TEST FAIL ❌ No UI Code" "$RECEIVER_EMAIL"
                                exit 1
                            fi

                            echo "📦 Installing NPM dependencies..."
                            npm install

                            echo "🎭 Installing Playwright dependencies..."
                            npx playwright install --with-deps

                            echo "▶ Running UI Tests..."
                            if npx playwright test; then
                                echo "✅ Tests Passed" | mail -s "TEST STATUS ✅ PASSED" "$RECEIVER_EMAIL"
                            else
                                echo "❌ Tests Failed" | mail -s "TEST STATUS ❌ FAILED" "$RECEIVER_EMAIL"
                            fi

                            service postfix stop
                        '
                """
            }
        }

        stage('Build & Deploy') {
            steps {
                echo "🚀 Building & Deploying Application..."
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline finished!"
            echo "📌 Check email for test results"
        }
    }
}
