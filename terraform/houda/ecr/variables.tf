variable "aws_region" {
  description = "AWS region to create the image repositories in (must match the other modules)"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Name prefix used for every repository (<project_name>/<image>)"
  type        = string
  default     = "cloud-design"
}

variable "images" {
  description = "One repository is created per image. The databases run on RDS, so they have no image here"
  type        = list(string)
  default     = ["api-gateway-app", "inventory-app", "billing-app", "rabbit-queue"]
}

variable "images_to_keep" {
  description = "How many images each repository keeps before the oldest are expired"
  type        = number
  default     = 5
}

variable "enhanced_scanning" {
  description = "Scan images continuously with Amazon Inspector (true) or once at push with ECR basic scanning (false). Use false in accounts where a service control policy denies inspector2:Enable"
  type        = bool
  default     = true
}
