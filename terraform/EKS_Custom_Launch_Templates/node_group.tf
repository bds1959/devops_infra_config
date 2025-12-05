resource "aws_eks_node_group" "application" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-application-custom-launch-template-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  capacity_type = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.eks_launch_template.id
    version = aws_launch_template.eks_launch_template.latest_version  # Starts at 1
  }

  # Taints for system pods
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_EXECUTE"
  }

  # Labels
  labels = {
    "node.kubernetes.io/scope" = "application"
  }

  tags = {
    Owner = "bceksprd1"
  }

  depends_on = [aws_launch_template.eks_launch_template]
}
