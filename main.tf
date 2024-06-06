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

  egress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_instance" "tpd_user_2" {
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
    Name = "TPD_USER_2"
  }
}

resource "aws_instance" "tpd_book_2" {
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
    Name = "TPD_BOOK_2"
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "tpd_user" {
  name               = "tpd-user-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all_traffic.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tpd_user" {
  name     = "tpd-user-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "tpd_user" {
  load_balancer_arn = aws_lb.tpd_user.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tpd_user.arn
  }
}

resource "aws_lb_target_group_attachment" "tpd_user" {
  target_group_arn = aws_lb_target_group.tpd_user.arn
  target_id        = aws_instance.tpd_user.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "tpd_user_2" {
  target_group_arn = aws_lb_target_group.tpd_user.arn
  target_id        = aws_instance.tpd_user_2.id
  port             = 8080
}

resource "aws_lb" "tpd_book" {
  name               = "tpd-book-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all_traffic.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tpd_book" {
  name     = "tpd-book-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "tpd_book" {
  load_balancer_arn = aws_lb.tpd_book.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tpd_book.arn
  }
}

resource "aws_lb_target_group_attachment" "tpd_book" {
  target_group_arn = aws_lb_target_group.tpd_book.arn
  target_id        = aws_instance.tpd_book.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "tpd_book_2" {
  target_group_arn = aws_lb_target_group.tpd_book.arn
  target_id        = aws_instance.tpd_book_2.id
  port             = 8080
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
      "sed -i 's|user_endpoint=localhost:8080|user_endpoint=${aws_lb.tpd_user.dns_name}:8080|g' TPD_WEB/src/main/resources/config.properties",
      "sed -i 's|book_endpoint=localhost:8080|book_endpoint=${aws_lb.tpd_book.dns_name}:8080|g' TPD_WEB/src/main/resources/config.properties",
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

resource "aws_instance" "tpd_web_2" {
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
      "sed -i 's|user_endpoint=localhost:8080|user_endpoint=${aws_lb.tpd_user.dns_name}:8080|g' TPD_WEB/src/main/resources/config.properties",
      "sed -i 's|book_endpoint=localhost:8080|book_endpoint=${aws_lb.tpd_book.dns_name}:8080|g' TPD_WEB/src/main/resources/config.properties",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/tpd_aws")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "TPD_WEB_2"
  }
}


resource "aws_lb" "tpd_web" {
  name               = "tpd-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.all_traffic.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "tpd_web" {
  name     = "tpd-web-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }
}

resource "aws_lb_listener" "tpd_web" {
  load_balancer_arn = aws_lb.tpd_web.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tpd_web.arn
  }
}

resource "aws_lb_target_group_attachment" "tpd_web" {
  target_group_arn = aws_lb_target_group.tpd_web.arn
  target_id        = aws_instance.tpd_web.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "tpd_web_2" {
  target_group_arn = aws_lb_target_group.tpd_web.arn
  target_id        = aws_instance.tpd_web_2.id
  port             = 8080
}
