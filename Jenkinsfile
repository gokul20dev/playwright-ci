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

        stage('Prepare Tests') {
            steps {
                sh '''
                    cd "${WORKSPACE}"

                    if [ ! -f package.json ]; then
                        npm init -y
                        npm install @playwright/test
                        npx playwright install
                    fi
                '''
            }
        }

        stage('Trigger UI Tests in Background') {
            steps {
                echo "⚡ Running Playwright Test Container in Background..."

                sh """
                    docker rm -f pwtest || true

                    docker run -d --name pwtest \
                        -v "${WORKSPACE}":/workspace \
                        -w /workspace \
                        -e RECEIVER_EMAIL="${RECEIVER_EMAIL}" \
                        mcr.microsoft.com/playwright:v1.44.0-jammy \
                        sh -c '
                            apt-get update &&
                            apt-get install -y mailutils &&
                            npm install &&
                            npx playwright install --with-deps &&

                            if npx playwright test ; then
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
                echo "🚀 Build & Deploy triggered..."
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline finished successfully!"
        }
    }
}
