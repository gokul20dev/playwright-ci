parameters {
    choice(
        name: 'TEST_SUITE',
        choices: ['Exammaker', 'Examtaker', 'reports', 'all'],
        description: 'Select which Playwright test suite to run'
    )
}

environment {
    NODE_HOME = tool name: 'nodejs', type: 'nodejs'
    PATH = "${NODE_HOME}/bin:${env.PATH}"

    DOCKER_HOST = "tcp://host.docker.internal:2375"

    // AWS Config
    AWS_REGION = "ap-south-1"
    S3_BUCKET = "playwright-test-reports-gokul"
    IMAGE_NAME = "gokul603/playwright-email-tests"
}

stages {

   
    stage('Pre-clean Old Containers') {
        steps {
            script {
                def containerName = "pw_test_${params.TEST_SUITE}"
                echo "🧹 Checking for leftover container from previous runs..."
                sh "docker rm -f ${containerName} || true"
                echo "✅ Old container (if any) removed. Ready to start fresh!"
            }
        }
    }

    
    stage('Run Playwright Tests in Docker') {
        steps {
            script {
                def containerName = "pw_test_${params.TEST_SUITE}"

                withCredentials([
                    usernamePassword(
                        credentialsId: 'gmail-smtp',
                        usernameVariable: 'GMAIL_USER',
                        passwordVariable: 'GMAIL_PASS'
                    ),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-s3-access']
                ]) {

                    echo "🚀 Running Playwright test suite: ${params.TEST_SUITE}"

                    // ✅ Run new container (don't remove after finish)
                    sh """
                        docker run -d --name ${containerName} \\
                          -e "GMAIL_USER=${GMAIL_USER}" \\
                          -e "GMAIL_PASS=${GMAIL_PASS}" \\
                          -e "AWS_REGION=${AWS_REGION}" \\
                          -e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \\
                          -e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \\
                          -e "S3_BUCKET=${S3_BUCKET}" \\
                          -e "TEST_SUITE=${params.TEST_SUITE}" \\
                          ${IMAGE_NAME}:latest
                    """

                    echo "✅ Container '${containerName}' started successfully."
                }
            }
        }
    }

   
    stage('Build') {
        steps {
            echo "🏗️ This is a dummy Build stage — no actual commands."
            echo "✅ Simulating build success..."
            sleep(time: 2, unit: 'SECONDS')
        }
    }

    
    stage('Deploy') {
        steps {
            echo "🚀 This is a dummy Deploy stage — no actual commands."
            echo "✅ Simulating deployment success..."
            sleep(time: 2, unit: 'SECONDS')
        }
    }
}


post {
    success {
        echo "📬 CI/CD pipeline ran through all stages successfully ✅"
        echo "🧩 Container will remain running for inspection (not auto-removed)."
    }

    failure {
        echo "❌ Pipeline failed — check console logs for details"
        echo "⚠️ Container preserved for debugging."
    }
}
