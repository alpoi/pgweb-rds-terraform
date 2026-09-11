resource "aws_iam_role" "this" {
  name               = "${var.resource_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.resource_prefix}-profile"
  role = aws_iam_role.this.name
  tags = var.tags
}
