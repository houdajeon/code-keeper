# force_delete lets `terraform destroy` remove a repository that still holds
# images, so tearing the project down after testing is a single command.
resource "aws_ecr_repository" "this" {
  for_each = toset(var.images)

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}

# Every push of :latest leaves the previous image untagged; this keeps
# storage (and cost) bounded instead of growing with every rebuild.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.images_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Vulnerability scanning
# -----------------------------------------------------------------------------
# Enhanced scanning (default): Amazon Inspector scans each image when it is
# pushed, then keeps re-checking it and reports new findings whenever a
# vulnerability affecting its packages is published, instead of scanning only
# once at push time.
#
# Some accounts cannot turn Inspector on (for example when an AWS
# Organizations service control policy denies inspector2:Enable). Setting
# enhanced_scanning = false falls back to ECR's built-in basic scanning,
# which scans each image once, when it is pushed.
data "aws_caller_identity" "current" {}

resource "aws_inspector2_enabler" "ecr" {
  count = var.enhanced_scanning ? 1 : 0

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = var.enhanced_scanning ? "ENHANCED" : "BASIC"

  rule {
    scan_frequency = var.enhanced_scanning ? "CONTINUOUS_SCAN" : "SCAN_ON_PUSH"

    repository_filter {
      filter      = "${var.project_name}/*"
      filter_type = "WILDCARD"
    }
  }

  depends_on = [aws_inspector2_enabler.ecr]
}
