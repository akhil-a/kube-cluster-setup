resource "aws_security_group" "kube_sg" {
  name   = "kube-setup-sg"
  vpc_id = "vpc-04364b568bb458ae7"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "kube-setup-sg"
  }

}

resource "aws_security_group_rule" "kube-ssh-ingress-rule" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kube_sg.id
}

resource "aws_security_group_rule" "kube-nginx-ingress-rule" {
  type              = "ingress"
  from_port         = 30080
  to_port           = 30080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kube_sg.id
}