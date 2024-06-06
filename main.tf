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
  name        = "all_traffic"
  description = "Allow inbound and outbound traffic only on port 8080 and port 22"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
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


resource "aws_instance" "tpd_user" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.small"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.all_traffic.name]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt upgrade -y",
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
      "sed -i 's|_POSTGRES_CHANGEME_URL_|${aws_db_instance.postgres.endpoint}|g' TPD_EAR_USER/pom.xml",
      "sed -i 's|_POSTGRES_CHANGEME_USERNAME_|${var.postgres_username}|g' TPD_EAR_USER/pom.xml",
      "sed -i 's|_POSTGRES_CHANGEME_PASSWORD_|${var.postgres_password}|g' TPD_EAR_USER/pom.xml",
      "mvn clean install",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "TPD_USER"
  }
}

resource "aws_instance" "tpd_book" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.small"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.all_traffic.name]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt upgrade -y",
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
      "sed -i 's|_POSTGRES_CHANGEME_URL_|${aws_db_instance.postgres.endpoint}|g' TPD_EAR_BOOK/pom.xml",
      "sed -i 's|_POSTGRES_CHANGEME_USERNAME_|${var.postgres_username}|g' TPD_EAR_BOOK/pom.xml",
      "sed -i 's|_POSTGRES_CHANGEME_PASSWORD_|${var.postgres_password}|g' TPD_EAR_BOOK/pom.xml",
      "mvn clean install",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "TPD_BOOK"
  }
}

resource "aws_instance" "tpd_web" {
  ami             = "ami-04b70fa74e45c3917"
  instance_type   = "t2.small"
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.all_traffic.name]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt upgrade -y",
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
      "mvn clean install",
      "sed -i 's|user_endpoint=localhost:8080|user_endpoint=${aws_instance.tpd_user.public_ip}:8080|g' TPD_WEB/src/main/resources/config.properties",
      "sed -i 's|book_endpoint=localhost:8080|book_endpoint=${aws_instance.tpd_book.public_ip}:8080|g' TPD_WEB/src/main/resources/config.properties",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "TPD_WEB"
  }
}
