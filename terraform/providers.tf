provider "aws" {
  region = "us-east-1"
  profile = "devops"
}

provider "aws" {
    region = "us-east-1"
    alias = "app_global"
    profile = "devops"
}

provider "aws" {
    region = "ap-northeast-1"
    alias = "app_local"
    profile = "devops"
}
