terraform {
  backend "s3" {
    bucket         = "vj-test-benvolate"
    key            = "build/terraform.tfstate"  # change per module (e.g., efs/, ec2/)
    region         = "us-east-2"
    encrypt        = true     
  }
}
