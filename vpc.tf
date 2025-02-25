terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}
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

# 3. 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id # 2에서 생성한 VPC를 인터넷 게이트웨이에 연결

  tags = {
    Name = "my-igw"
  }
}

# 4. 라우팅 테이블 생성
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0" # 퍼블릭 접속 허용
    gateway_id = aws_internet_gateway.igw.id # 3에서 생성한 인터넷 게이트웨이와 연결
  }

  tags = {
    Name = "my-route-table"
  }
}

# 5. 퍼블릭 서브넷 생성 1
resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "my-public-subnet-1"
  }
}

# 6. 라우팅 테이블 연결 퍼블릭 서브넷1
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.rt.id
}

# 7. 보안 그룹 생성(SSH)
resource "aws_security_group" "ssh" {
  vpc_id = aws_vpc.vpc.id
  ingress { # 인바운드 정책(들어오는)
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 접속 허용
  }

  egress { # 아웃바운드 정책(내보내는)
    from_port = 0
    to_port = 0
    protocol = "-1" # 모든 프로토콜을 허용 하겠다.
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-ssh-sg"
  }
}

# 8. 개인키 생성
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits = 2048
}

# 9. 생성된 개인키를 활용하여 키페어 생성
resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  public_key = tls_private_key.my_key.public_key_openssh
}

# 10. 로컬에 키 파일 생성
resource "local_file" "private_key" {
  content = tls_private_key.my_key.private_key_pem
  filename = "${path.module}/my_key.pem"
}

# 11. 퍼블릭 서브넷에 EC2 인스턴스 생성
resource "aws_instance" "my_instance" {
  ami = "ami-024ea438ab0376a47"
  instance_type = "t2.micro"
  key_name = aws_key_pair.my_key.key_name
  subnet_id = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "my-ec2-instance"
  }
}