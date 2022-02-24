pipeline {
    agent any
    tools{
        terraform 'terraform'
    }
    
    stages {
        
        stage ('Terraform init'){
            steps {
                sh 'terraform init -input=false'    
            }
            
        }
        
        stage ('Terraform validate'){
            steps {
                sh 'terraform validate'    
            }
            
        }
        
        stage ('Terraform plan'){
            steps {
                sh 'terraform plan -out=tfplan -input=false'
            }
            
        }
        
        stage ('Email Notification'){
            steps {
                mail bcc: '', body: 'The jenkins build for CI was successful', cc: '', from: '', replyTo: '', subject: 'Jenkins Build Successful', to: 'ameydevarshi1@gmail.com'
            }
           
            
        }
  }
}
