#terraform {
#  required_providers {
#    aws = {
#      source  = "hashicorp/aws"
#      version = "~> 4.0"
#    }
#  }
#}
#provider "aws"{
#    region = "us-east-1"
#}
#resource "aws_kms_key" "s3bucketkey" {
#  description             = "This key is used to encrypt bucket objects"
# deletion_window_in_days = 8
#}
resource "aws_s3_bucket" "s3_bucket"{
    bucket = "terraform-first-bucket-cloudjourney"
    
}