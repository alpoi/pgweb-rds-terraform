#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/pgweb-setup.log) 2>&1

dnf -y update
dnf -y install jq unzip awscli libcap

DATABASE_URL="postgres://${db_username}:${db_password}@${db_endpoint}:${db_port}/${db_name}?sslmode=${db_sslmode}"

install -d -m 700 /etc/pgweb
cat > /etc/pgweb/env <<EOF
DATABASE_URL=$${DATABASE_URL}
EOF
chmod 600 /etc/pgweb/env

%{ if pgweb_version == "latest" }
PGWEB_TAG=$(curl -fsSL https://api.github.com/repos/sosedoff/pgweb/releases/latest | jq -r '.tag_name')
%{ else }
PGWEB_TAG="v${pgweb_version}"
%{ endif }

curl -fsSL -o /tmp/pgweb.zip "https://github.com/sosedoff/pgweb/releases/download/$${PGWEB_TAG}/pgweb_linux_arm64.zip"
unzip -o /tmp/pgweb.zip -d /tmp/pgweb
mv /tmp/pgweb/pgweb_linux_arm64 /usr/local/bin/pgweb
chmod +x /usr/local/bin/pgweb
rm -rf /tmp/pgweb /tmp/pgweb.zip

useradd --system --no-create-home --shell /sbin/nologin pgweb || true

cat > /etc/systemd/system/pgweb.service <<'EOF'
[Unit]
Description=pgweb
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=/etc/pgweb/env
User=pgweb
ExecStart=/usr/local/bin/pgweb --bind=127.0.0.1 --listen=8081 --sessions %{ if pgweb_readonly }--readonly%{ endif }
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now pgweb

CADDY_TAG=$(curl -fsSL https://api.github.com/repos/caddyserver/caddy/releases/latest | jq -r '.tag_name')
CADDY_VERSION=$${CADDY_TAG#v}

curl -fsSL -o /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/$${CADDY_TAG}/caddy_$${CADDY_VERSION}_linux_arm64.tar.gz"
tar -xzf /tmp/caddy.tar.gz -C /tmp caddy
mv /tmp/caddy /usr/local/bin/caddy
chmod +x /usr/local/bin/caddy
rm -f /tmp/caddy.tar.gz
setcap cap_net_bind_service=+ep /usr/local/bin/caddy

id caddy &>/dev/null || useradd --system --no-create-home --shell /sbin/nologin caddy
install -d -m 755 -o caddy -g caddy /etc/caddy /var/lib/caddy

cat > /etc/caddy/Caddyfile <<EOF
%{ if domain_name != null }
{
	email ${domain_email}
}

${domain_name} {
	reverse_proxy 127.0.0.1:8081
	basic_auth {
		${pgweb_username} ${pgweb_hash}
	}
}
%{ else }
:443 {
	tls internal
	reverse_proxy 127.0.0.1:8081
	basic_auth {
		${pgweb_username} ${pgweb_hash}
	}
}
%{ endif }
EOF
chown caddy:caddy /etc/caddy/Caddyfile

cat > /etc/systemd/system/caddy.service <<'EOF'
[Unit]
Description=Caddy
After=network-online.target
Wants=network-online.target

[Service]
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now caddy
