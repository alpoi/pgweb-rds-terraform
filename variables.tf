variable "resource_prefix" {
  description = "Prefix used for all resource names created by this module."
  type        = string
  default     = "pgweb"
}

variable "vpc_id" {
  description = "The ID for the VPC in which the RDS instance lives."
  type        = string
}

variable "rds_security_group_id" {
  description = "The ID for the security group attached to the RDS instance."
  type        = string
}

variable "public_subnet_id" {
  description = "The ID for an existing public subnet, created if not provided."
  type        = string
  default     = null
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach pgweb over HTTPS (443)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "availability_zone" {
  description = "The availability zone to deploy regional resources."
  type        = string
  default     = null
}

variable "db_config" {
  description = "Configuration for the RDS instance."

  type = object({
    endpoint = string
    port     = optional(number, 5432)
    name     = string
    sslmode  = optional(string, "require")
    username = string
    password = string
  })

  sensitive = true
}

variable "pgweb_config" {
  description = "Configuration for pgweb."

  type = object({
    version  = optional(string, "latest")
    readonly = optional(bool, false)
    username = string
    password = string
  })

  sensitive = true
}

variable "domain_config" {
  description = "Domain configuration for cert signing. Requires you to point your DNS at the EC2's public ip."

  type = object({
    name  = string
    email = string
  })

  default = {
    name  = null
    email = null
  }
}

variable "tags" {
  description = "Extra tags to apply to resources."
  type        = map(string)
  default     = {}
}
