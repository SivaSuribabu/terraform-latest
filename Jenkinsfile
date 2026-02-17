pipeline {
    agent any

    environment {
        AWS_REGION          = "us-east-1"
        APP_NAME            = "monolith-app"
        ARTIFACT_BUCKET     = "monolith-artifacts-prod"
        TF_ENVIRONMENT      = "uat"
        BUILD_VERSION       = "${env.BUILD_NUMBER}"
        NEW_COLOR           = "green"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        githubPush()
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Upload Artifact to S3') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-prod-creds']]) {
                    sh """
                        aws s3 cp target/ROOT.war \
                        s3://${ARTIFACT_BUCKET}/ROOT-${BUILD_VERSION}.war \
                        --region ${AWS_REGION}
                    """
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir("terraform/environments/${TF_ENVIRONMENT}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("terraform/environments/${TF_ENVIRONMENT}") {
                    sh """
                        terraform plan \
                        -var="build_number=${BUILD_VERSION}" \
                        -var="environment_color=${NEW_COLOR}" \
                        -out=tfplan
                    """
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input message: "Approve Terraform Apply to ${TF_ENVIRONMENT}?"
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("terraform/environments/${TF_ENVIRONMENT}") {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Warmup Wait') {
            steps {
                sh 'sleep 120'
            }
        }

        stage('Smoke Test (5 min)') {
            steps {
                script {
                    sh """
                        END=$((SECONDS+300))
                        while [ \$SECONDS -lt \$END ]; do
                          curl -f https://${APP_NAME}-${NEW_COLOR}.elasticbeanstalk.com/health || exit 1
                          sleep 15
                        done
                    """
                }
            }
        }

        stage('Blue/Green Swap') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-prod-creds']]) {
                    sh """
                        CURRENT_ENV=\$(aws elasticbeanstalk describe-environments \
                          --application-name ${APP_NAME} \
                          --query "Environments[?Status=='Ready'].EnvironmentName" \
                          --output text)

                        aws elasticbeanstalk swap-environment-cnames \
                          --source-environment-name ${APP_NAME}-${NEW_COLOR} \
                          --destination-environment-name \$CURRENT_ENV
                    """
                }
            }
        }

        stage('CloudFront Invalidation') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-prod-creds']]) {
                    sh """
                        DISTRIBUTION_ID=\$(aws cloudfront list-distributions \
                          --query "DistributionList.Items[?Comment=='${APP_NAME}'].Id" \
                          --output text)

                        aws cloudfront create-invalidation \
                          --distribution-id \$DISTRIBUTION_ID \
                          --paths "/*"
                    """
                }
            }
        }
    }

    post {

        failure {
            echo "Deployment failed. Initiating rollback..."

            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-prod-creds']]) {
                sh """
                    PREVIOUS_COLOR="blue"

                    aws elasticbeanstalk swap-environment-cnames \
                      --source-environment-name ${APP_NAME}-\$PREVIOUS_COLOR \
                      --destination-environment-name ${APP_NAME}-${NEW_COLOR}
                """
            }
        }

        success {
            echo "Deployment completed successfully."
        }
    }
}