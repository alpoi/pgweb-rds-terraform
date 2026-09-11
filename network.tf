locals {
  create_subnet     = var.public_subnet_id == null
  availability_zone = coalesce(var.availability_zone, data.aws_availability_zones.available.names[0])
  public_subnet_id  = coalesce(var.public_subnet_id, aws_subnet.public[0].id)
}

resource "aws_security_group" "pgweb" {
  name        = "${var.resource_prefix}-sg"
  description = "pgweb host, inbound HTTPS, outbound RDS and internet"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  count             = length(var.allowed_cidrs)
  security_group_id = aws_security_group.pgweb.id
  description       = "HTTPS to pgweb (via Caddy)"
  cidr_ipv4         = var.allowed_cidrs[count.index]
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.pgweb.id
  description       = "All outbound (RDS, Let's Encrypt, pgweb)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_pgweb" {
  security_group_id            = var.rds_security_group_id
  description                  = "RDS from pgweb"
  referenced_security_group_id = aws_security_group.pgweb.id
  from_port                    = var.db_config.port
  to_port                      = var.db_config.port
  ip_protocol                  = "tcp"
}

resource "aws_internet_gateway" "this" {
  count  = local.create_subnet ? 1 : 0
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_subnet" "public" {
  count             = local.create_subnet ? 1 : 0
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = local.availability_zone
  tags              = var.tags
}

resource "aws_route_table" "public" {
  count  = local.create_subnet ? 1 : 0
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = var.tags
}

resource "aws_route_table_association" "public" {
  count          = local.create_subnet ? 1 : 0
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}
