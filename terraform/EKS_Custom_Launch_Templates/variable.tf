variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
  default     = "vpc-09dec912ddb44300e"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "bceksprd1"
}

variable "subnet_ids" {
  description = "List of subnets where the node groups will be created"
  type        = list(string)
  default     = ["subnet-066775f6d45f84f47", "subnet-046d543448f9d4fe5", "subnet-024b30f67aed5f05c"]
}

variable "instance_type" {
  description = "The EC2 instance type for the worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "max_pods" {
  description = "The maximum number of pods that can run on a worker node"
  type        = number
  default     = 17
}

variable "ami_id" {
  description = "The AMI ID for the EKS-optimized AMI"
  type        = string
  default     = "ami-0bcdfb9a5f7c055fd"
}

variable "eks_optimized_image_id" {
  default = "ami-0bcdfb9a5f7c055fd"
}

variable "node_role_arn" {
  description = "The IAM role ARN for the node group"
  type        = string
  default     = "arn:aws:iam::100969885024:role/bcAmazonEKSNodeRole"
}

variable "api_server" {
  description = "The API server endpoint for the EKS cluster"
  type        = string
}

variable "certificate_authority" {
  description = "The base64 encoded certificate authority for the EKS cluster"
  type        = string
}

variable "dns_cluster_ip" {
  description = "The DNS cluster IP for the EKS cluster"
  type        = string
}

variable "kms_key_id" {
  description = "The KMS_KEY_ID for the ec2 volume encrypt"
  type        = string
  default     = "arn:aws:kms:us-east-2:100969885024:key/186a7f6d-959b-4c30-8d30-5b353aa1ea9f"
}
