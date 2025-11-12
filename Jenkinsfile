       🧹 Post Cleanup
    ───────────────────────────────── */
    post {
        always {
            echo "🧹 Cleaning up leftover containers (if any)..."
            script {
                def containerName = "pw_test_${params.TEST_SUITE}"
                sh "docker rm -f ${containerName} || true"
                echo "🧽 Cleanup done."
            }
        }

        success {
            echo "📬 Email report sent — check your inbox ✅"
        }

        failure {
            echo "❌ Pipeline failed — check console logs for errors"
        }
    }
}

