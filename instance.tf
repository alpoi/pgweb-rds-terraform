resource "aws_instance" "pgweb" {
  ami                         = data.aws_ssm_parameter.al2023_arm64.value
  instance_type               = "t4g.nano"
  subnet_id                   = var.public_subnet_id || aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.pgweb.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 2
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    pgweb_version  = var.pgweb_config.version
    pgweb_readonly = var.pgweb_config.readonly
    pgweb_username = var.pgweb_config.username
    pgweb_hash     = bcrypt(var.pgweb_config.password)
    db_endpoint    = var.db_config.endpoint
    db_port        = var.db_config.port
    db_name        = var.db_config.name
    db_sslmode     = var.db_config.sslmode
    db_username    = var.db_config.username
    db_password    = var.db_config.password
    domain_name    = var.domain_config.name
    domain_email   = var.domain_config.email
    aws_region     = data.aws_region.current.region
  })

  user_data_replace_on_change = true
  tags                        = var.tags
}
