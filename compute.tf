resource "aws_security_group" "my_lb__ec2_sg" {
  name        = "mysecuritygroup"
  description = "open the port 22 and 80"
  vpc_id      = local.myvpcid
  tags = {
    Name = "allow_all"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_vpc.trailvpc]
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/id_ed25519.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "myec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.my_lb__ec2_sg.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnets[0].id
  key_name                    = aws_key_pair.mykeypair.key_name
  depends_on                  = [aws_security_group.my_lb__ec2_sg]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install nginx -y"
    ]
    connection {
      type        = "ssh"
      host        = self.public_ip
      private_key = file("~/.ssh/id_ed25519")
      user        = "ubuntu"
    }
  }


}

resource "aws_lb_target_group" "myalb_target_group" {
  name       = "tf-example-lb-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = local.myvpcid
  depends_on = [aws_vpc.trailvpc]
}

resource "aws_lb" "myLoadBalncer" {
  name               = "ApplicationLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_lb__ec2_sg.id]
  subnet_mapping {
    subnet_id = aws_subnet.subnets[1].id
  }

  subnet_mapping {
    subnet_id = aws_subnet.subnets[3].id
  }

  depends_on = [aws_security_group.my_lb__ec2_sg, aws_subnet.subnets]
}

resource "aws_lb_target_group_attachment" "MytargetGroupAttachment" {
  target_group_arn = aws_lb_target_group.myalb_target_group.arn
  target_id        = aws_instance.myec2.id
  port             = "80"
  depends_on       = [aws_lb_target_group.myalb_target_group]
}




output "publicIp" {
  value = aws_instance.myec2.public_ip
}


output "loadbalncerdns" {
  value = aws_lb.myLoadBalncer.dns_name
}


