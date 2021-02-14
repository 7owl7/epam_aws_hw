#----------------------------------------------------------
# EPAM aws homework main.tf file
#----------------------------------------------------------

provider "aws" {
  region = var.region
}


data "aws_ami" "latest_ubuntu_linux" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


resource "aws_key_pair" "admin_key" {
  key_name   = "${var.project_name}-${var.env}-admin_key"
  public_key = file("admin_private.key.pub")
}

resource "aws_db_subnet_group" "wpress" {
  name       = "${var.project_name}-${var.env}-db_subnet_group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "${var.project_name}-${var.env} DB subnet group"
  }
}

resource "aws_db_instance" "wpress" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "wordpress"
  username               = "wpadmin"
  password               = var.dbpw
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = "true"
  db_subnet_group_name   = aws_db_subnet_group.wpress.id
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_efs_file_system" "wpress" {
  creation_token = "${var.project_name}-${var.env}-efs"

  tags = {
    Name = "${var.project_name}-${var.env}-efs"
  }
}

resource "aws_efs_mount_target" "subnet1" {
  file_system_id  = aws_efs_file_system.wpress.id
  subnet_id       = aws_subnet.subnet1.id
  ip_address      = "10.77.10.100"
  security_groups = [aws_security_group.nfs.id]
}

resource "aws_efs_mount_target" "subnet2" {
  file_system_id  = aws_efs_file_system.wpress.id
  subnet_id       = aws_subnet.subnet2.id
  ip_address      = "10.77.11.100"
  security_groups = [aws_security_group.nfs.id]
}

resource "aws_instance" "wp1" {
  ami                         = data.aws_ami.latest_ubuntu_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.admin_key.id
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids      = [aws_security_group.wpress.id]
  tags = {
    Name = "${var.project_name}-${var.env}-wordpress1"
  }

  provisioner "remote-exec" {
    inline = ["echo VM started"]
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("admin_private.key")
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key admin_private.key ansible/wp1_playbook.yml -e 'efs_ip_address=${aws_efs_mount_target.subnet1.ip_address}' -e 'db_host=${aws_db_instance.wpress.address}' -e 'db_password=${var.dbpw}'"
  }
}

resource "aws_instance" "wp2" {
  ami                         = data.aws_ami.latest_ubuntu_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.admin_key.id
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet2.id
  vpc_security_group_ids      = [aws_security_group.wpress.id]
  tags = {
    Name = "${var.project_name}-${var.env}-wordpress2"
  }

  provisioner "remote-exec" {
    inline = ["echo VM started"]
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("admin_private.key")
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${self.public_ip},' --private-key admin_private.key ansible/wp2_playbook.yml -e 'efs_ip_address=${aws_efs_mount_target.subnet2.ip_address}'"
  }
  depends_on = [aws_instance.wp1]
}

resource "aws_lb" "alb_wp" {
  name               = "${var.project_name}-${var.env}-LB-wpress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  tags = {
    Name = "${var.project_name}-${var.env}-LB-wpress"
  }
}

resource "aws_lb_target_group" "tg_wp" {
  name        = "${var.project_name}-${var.env}-TG-wpress"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "tcp_80" {
  load_balancer_arn = aws_lb.alb_wp.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_wp.arn
  }
}

resource "aws_lb_target_group_attachment" "wp1" {
  target_group_arn = aws_lb_target_group.tg_wp.arn
  target_id        = aws_instance.wp1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "wp2" {
  target_group_arn = aws_lb_target_group.tg_wp.arn
  target_id        = aws_instance.wp2.id
  port             = 80
}
