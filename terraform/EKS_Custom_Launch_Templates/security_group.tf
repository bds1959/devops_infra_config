resource "aws_security_group" "eks_custom_sg" {
  name        = "bceksprd1_EKS_SG_Custom_Launch_Template_27Nov25"
  description = "bceksprd1 EKS cluster custom launch template 27Nov25"
  vpc_id      = var.vpc_id

  tags = {
    owner = "bceksprd1"
  }
}

resource "aws_security_group_rule" "allow_all_worker_nodes" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_custom_sg.id
  source_security_group_id = aws_security_group.eks_custom_sg.id
}

resource "aws_security_group_rule" "allow_control_plane" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_custom_sg.id
  source_security_group_id = "sg-0bb2387b353c4f455" # Replace with your cluster security group ID
}

resource "aws_security_group_rule" "allow_control_plane_to_worker_nodes" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "sg-0bb2387b353c4f455"
  source_security_group_id = aws_security_group.eks_custom_sg.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_custom_sg.id
}

# In main.tf, after aws_security_group.eks_custom_sg
resource "aws_security_group_rule" "outbound_aws_apis" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_custom_sg.id
  cidr_blocks       = ["0.0.0.0/0"]  # Or restrict to AWS ranges
  description       = "Outbound HTTPS to AWS services (EC2/STS)"
}
