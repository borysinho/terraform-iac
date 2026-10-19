# Activar únicamente después de crear y verificar el bucket.
terraform {
  backend "s3" {
    bucket              = "globomatics-tofu-state-222234418877-us-east-2"
    key                 = "globomatics/backend/terraform.tfstate"
    region              = "us-east-2"
    encrypt             = true
    use_lockfile        = true
    allowed_account_ids = ["222234418877"]
  }
}
