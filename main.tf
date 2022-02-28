provider "aws" {
  region     = "eu-west-2"
}


#--------------VPC & subnets----------------

resource "aws_vpc" "terraform-vpc" {
  cidr_block            = "10.1.0.0/16"
  enable_dns_hostnames  = true

  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = "10.1.10.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "terraform-subnet-1a"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.terraform-vpc.id
  cidr_block        = "10.1.20.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name = "terraform-subnet-2b"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name= "terraform-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "terraform-public-route-table"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public.id
}


#---------------SG-------------------

resource "aws_security_group" "alb" {
  name   = "terraform-alb-sg"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-alb-sg"
  }
}

resource "aws_security_group" "webserver" {
  name   = "terraform-webserver-sg"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-webserver-sg"
  }
}

resource "aws_security_group" "efs" {
  name   = "terraform-efs-sg"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    from_port       = 2049
    protocol        = "tcp"
    to_port         = 2049
    security_groups = [aws_security_group.webserver.id]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-efs-sg"
  }
}

resource "aws_security_group" "rds" {
  name   = "terraform-rds-sg"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    security_groups = [aws_security_group.webserver.id]

  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-rds-sg"
  }
}


#---------------EC2-------------------

resource "aws_instance" "webserver1" {
  ami                         = "ami-0dd555eb7eb3b7c82"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.webserver.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/bash
yum update -y
yum install httpd php-mysql -y
yum install amazon-linux-extras -y
amazon-linux-extras install php7.4 -y
yum install amazon-efs-utils -y
mount -t efs -o tls ${aws_efs_file_system.my-efs.id}:/ /var/www/html
echo "${aws_efs_file_system.my-efs.id}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab
cd /var/www/html/
wget https://wordpress.org/wordpress-5.9.tar.gz
tar -xzf wordpress-5.9.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress/
rm -rf wordpress-5.9.tar.gz
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i 's/database_name_here/wpdb/' /var/www/html/wp-config.php
sed -i 's/username_here/wpuser/' /var/www/html/wp-config.php
sed -i 's/password_here/${data.aws_ssm_parameter.my_rds_password.value}/' /var/www/html/wp-config.php
sed -i 's/localhost/${aws_db_instance.my-db.endpoint}/' /var/www/html/wp-config.php
chown -R apache:apache /var/www/html/
chmod -R 755 wp-content
systemctl start httpd
systemctl enable httpd.service
EOF
  tags = {
    Name = "WebServer1 Build by Terraform"
  }
  depends_on = [aws_db_instance.my-db, aws_efs_mount_target.efs-mount-1]
}

resource "aws_instance" "webserver2" {
  ami                         = "ami-0dd555eb7eb3b7c82"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet2.id
  vpc_security_group_ids      = [aws_security_group.webserver.id]
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/bash
yum update -y
yum install httpd php-mysql -y
yum install amazon-linux-extras -y
amazon-linux-extras install php7.4 -y
yum install amazon-efs-utils -y
mount -t efs -o tls ${aws_efs_file_system.my-efs.id}:/ /var/www/html
echo "${aws_efs_file_system.my-efs.id}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab
systemctl start httpd
systemctl enable httpd.service
EOF
    tags = {
    Name = "WebServer2 Build by Terraform"
  }
  depends_on = [aws_instance.webserver1, aws_efs_mount_target.efs-mount-2]
}


#---------------EFS-------------------

resource "aws_efs_file_system" "my-efs" {
  tags = {
     Name = "terraform-EFS"
   }
}

resource "aws_efs_mount_target" "efs-mount-1" {
   file_system_id  = aws_efs_file_system.my-efs.id
   subnet_id       = aws_subnet.subnet1.id
   security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "efs-mount-2" {
   file_system_id  = aws_efs_file_system.my-efs.id
   subnet_id       = aws_subnet.subnet2.id
   security_groups = [aws_security_group.efs.id]
}


#---------------RDS-------------------

resource "aws_db_instance" "my-db" {
  identifier             = "terraform-rds-aws"
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  db_name                = "wpdb"
  username               = "wpuser"
  password               = data.aws_ssm_parameter.my_rds_password.value
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.db-subnets.name

  tags = {
     Name = "terraform-RDS"
   }

}

resource "aws_db_subnet_group" "db-subnets" {
  subnet_ids = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]

  tags = {
    Name = "terraform-db-subnets"
  }
}


#-------------RDS password--------------

resource "random_string" "rds_password" {
  length = 8
  special = false
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "rds-mysql"
  type        = "SecureString"
  value       = random_string.rds_password.result
  description = "Master pass for RDS MySQL"
}

data "aws_ssm_parameter" "my_rds_password" {
  name = "rds-mysql"

  depends_on = [aws_ssm_parameter.rds_password]
}


#--------------ALB-------------------------

resource "aws_lb" "my-alb" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id,aws_subnet.subnet2.id]
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "terraform-ALB"
  }

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }

  tags = {
    Name = "terraform-ALB-listener"
  }
}

resource "aws_lb_target_group" "alb-target-group" {
  health_check {
    interval            = 5
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.terraform-vpc.id

  tags = {
    Name = "terraform-ALB-target-group"
  }
}

resource "aws_alb_target_group_attachment" "webserver1" {
  target_group_arn = aws_lb_target_group.alb-target-group.arn
  target_id        = aws_instance.webserver1.id
}

resource "aws_alb_target_group_attachment" "webserver2" {
  target_group_arn = aws_lb_target_group.alb-target-group.arn
  target_id        = aws_instance.webserver2.id
}
