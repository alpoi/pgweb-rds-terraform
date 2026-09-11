# pgweb rds terraform

Stands up a small public EC2 instance running [pgweb](https://github.com/sosedoff/pgweb)
behind [Caddy](https://caddyserver.com) (automatic TLS + HTTP basic auth), pointed at an
existing RDS Postgres instance.

> [!IMPORTANT]
>
> Caddy issues a self-signed certificate, so browsers will show a warning. 
> Set the `domain_config` variables and point your DNS at the instance's `public_ip`
> output for a trusted certificate.

## Example

```hcl
module "pgweb" {
  source = "git::https://github.com/alpoi/pgweb-rds-terraform?ref=v0.0.0"

  vpc_id                 = module.vpc.vpc_id
  rds_security_group_id  = module.rds.db_instance_security_group_id
  
  db_config = {
    endpoint = module.rds.db_endpoint
    port     = module.rds.db_port
    name     = module.rds.db_name
    sslmode  = module.rds.db_sslmode
    username = module.rds.db_username
    password = module.rds.db_password
  }

  pgweb_config = {
    username = "admin"
    password = var.pgweb_password
  }
}
```
