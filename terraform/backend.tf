terraform {
  backend "s3" {
    bucket = "cloud-sec-final-terraform"
    key    = "tfstate"
    region = "us-east-1"
  }
}
