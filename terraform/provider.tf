terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
        }
        tls = {
            source  = "hashicorp/tls"
        }
    }
}

provider "aws" {}
provider "tls" {}
