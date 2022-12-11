provider "aws" {
  default_tags {
    tags = {
      Workspace = terraform.workspace
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
