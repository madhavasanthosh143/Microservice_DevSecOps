# Remote state in S3 with DynamoDB locking. Bootstrap this bucket/table once,
# out of band, before running `terraform init` here (chicken-and-egg problem
# with managing your own state backend via Terraform).
#
# aws s3api create-bucket --bucket <org>-terraform-state --region <region>
# aws s3api put-bucket-versioning --bucket <org>-terraform-state --versioning-configuration Status=Enabled
# aws dynamodb create-table --table-name terraform-locks \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST

terraform {
  backend "s3" {
    bucket         = "msdemo-tfstate-075774507058"
    key            = "microservices-demo/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
