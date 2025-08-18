resource "aws_ecr_repository" "this" {
  name                 = "${var.env}-react-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "${var.env}-ecr" }
}


