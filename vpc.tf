# 1. AWS provider 설정
provider "aws" {
  region = "ap-northeast-2"
}

# 2. VPC 생성
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc" # vpc 이름
  }
}

# 3.