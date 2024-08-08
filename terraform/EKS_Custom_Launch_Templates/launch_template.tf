resource "aws_launch_template" "eks_launch_template" {
  name = "bceksprd1_EKS_Custom_Launch_Template"

  image_id          = var.eks_optimized_image_id
  instance_type     = "t3.medium"  # Replace with your desired instance type
  user_data         = filebase64("userdata.txt")  # Replace with your userdata.txt content
  key_name          = "prd_launchpad"

  tag_specifications {
    resource_type = "volume"
    tags = {
      owner = "bceksprd1"
    }
  }

  tag_specifications {
    resource_type = "spot-instances-request"
    tags = {
      owner = "bceksprd1"
    }
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = {
      owner = "bceksprd1"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      owner = "bceksprd1"
    }
  }

  monitoring {
    enabled = true
  }

  disable_api_stop        = true
  disable_api_termination = true

  network_interfaces {
    device_index         = 0
    security_groups      = [aws_security_group.eks_custom_sg.id]
    associate_public_ip_address = true  # Adjust according to your network setup
  }
  block_device_mappings {
    device_name = "/dev/xvda"  # or the appropriate device name
    ebs {
      delete_on_termination = true
      volume_size           = 20  # Adjust the size as needed
      volume_type           = "gp2"  # General Purpose SSD, you can change this to gp3, io1, etc.
      encrypted             = true  # Enable encryption
      kms_key_id            = var.kms_key_id  # Optionally specify a custom KMS key
    }
  }
}

