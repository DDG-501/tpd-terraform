terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "tpd_aws"
  public_key = file("~/.ssh/tpd_aws.pub")
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "all_traffic" {
  name        = "allow_all_traffic"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier          = "tpdb-instance"
  engine              = "postgres"
  engine_version      = "16.2"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "tpdb"
  username            = var.postgres_username
  password            = var.postgres_password
  publicly_accessible = false
  skip_final_snapshot = true
}


resource "aws_instance" "tpd_1" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.small"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.all_traffic.name]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-17-jdk",
      "sudo apt-get install -y maven",
      "mkdir -p /home/ubuntu"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "~/tpd"
    destination = "/home/ubuntu/project"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu/project",
      "sed -i 's|_POSTGRES_CHANGEME_URL_|${aws_db_instance.postgres.endpoint}|g' TPD_EAR/pom.xml",
      "sed -i 's|_POSTGRES_CHANGEME_USERNAME_|${var.postgres_username}|g' TPD_EAR/pom.xml",
      "sed -i 's|_POSTGRES_CHANGEME_PASSWORD_|${var.postgres_password}|g' TPD_EAR/pom.xml",
      "mvn clean install",
      "mvn -pl TPD_EAR cargo:start",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "TPD1"
  }
}
