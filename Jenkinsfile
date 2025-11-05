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

        stage('Trigger UI Tests in Background') {
            steps {
                echo "⚡ Running Playwright Test Container in Background..."

                sh """
                    echo "🧹 Removing old container if exists..."
                    docker rm -f pwtest || true

                    echo "🚀 Launching Playwright Test Container..."
                    docker run -d --name pwtest \
                        -v "${WORKSPACE}":/workspace \
                        -w /workspace \
                        -e RECEIVER_EMAIL="${RECEIVER_EMAIL}" \
                        mcr.microsoft.com/playwright:v1.44.0-jammy \
                        bash -c '
                            set -e

                            export DEBIAN_FRONTEND=noninteractive;
                            echo "postfix postfix/main_mailer_type string Internet Site" | debconf-set-selections;
                            echo "postfix postfix/mailname string localhost" | debconf-set-selections;

                            apt-get update &&
                            apt-get install -y mailutils &&

                            echo "📦 Installing dependencies..." &&
                            npm install &&
                            npx playwright install --with-deps &&

                            echo "▶ Running tests..." &&
                            if npx playwright test; then
                                echo "✅ Tests Passed" | mail -s "TEST STATUS ✅ PASSED" "$RECEIVER_EMAIL"
                            else
                                echo "❌ Tests Failed" | mail -s "TEST STATUS ❌ FAILED" "$RECEIVER_EMAIL"
                            fi
                        '

                    echo "✅ Tests running in background... Pipeline continues!"
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
        }
    }
}
