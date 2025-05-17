## Dockflare Tutorial 

Official Documentation - https://github.com/ChrispyBacon-dev/DockFlare/wiki

### compose.yaml 

```
services:
  dockflare:
    image: alplat/dockflare:stable
    container_name: dockflare
    restart: unless-stopped
   # ports:
    #  - "5000:5000"  # Web UI port
    env_file:
      - .env  # Load environment variables from .env file
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro  # Required to monitor Docker events
      - ./data:/app/data  # Persistent storage for state
    networks:
      - cloudflared  # Network for communication with cloudflared agent
      - traefik

networks:
  cloudflared:
    external: true
  traefik:
    external: true

```


 ### .env File

```
# Required Cloudflare credentials
CF_API_TOKEN=
CF_ACCOUNT_ID=
CF_ZONE_ID=

# Tunnel configuration
TUNNEL_NAME=DockflareTunnel

# Optional configuration
GRACE_PERIOD_SECONDS=28800  # 8 hours before removing rules after container stops
LABEL_PREFIX=cloudflare.tunnel  # Prefix for Docker labels

# Optional: External cloudflared mode
# USE_EXTERNAL_CLOUDFLARED=true
# EXTERNAL_TUNNEL_ID=your_external_tunnel_id

# Optional: Scanning configuration
# SCAN_ALL_NETWORKS=true  # Scan containers across all Docker networks

```

There are four key variables:

1. **CF API Token** – Used for authentication with Cloudflare. (Zone:DNS:Edit and Account:Cloudflare Tunnel:Edit permissions)
2. **Cloudflare Account ID** – Identifies your Cloudflare account. (found in Cloudflare Dashboard → Overview)
3. **Zone ID** – Specifies the DNS zone you’re managing. (found in Cloudflare Dashboard → Overview)
4. **Tunnel Name** – Tunnel Name.


### Docker Labels

```
services:
  vaultwarden:
    image: vaultwarden/server:latest
    hostname: vaultwarden
    labels:
       # Enable DockFlare management for this container
      cloudflare.tunnel.enable: "true"

       # The public hostname to expose (must be a valid domain you control)
      cloudflare.tunnel.hostname: "vaultwarden.geniehome.net"

       # The internal service address (protocol://host:port)
      cloudflare.tunnel.service: "https://vault.traefik.geniehome.net"
    container_name: vaultwarden
    # network_mode: host
    #ports:
    # - 8080:80
    networks:
      - traefik
    env_file:
      - .env
    environment:
      DOMAIN: https://vault.traefik.geniehome.net
      LOG_FILE: /data/log/vaultwarden.log
      ADMIN_TOKEN: ${ADMIN_TOKEN}
     # SIGNUPS_ALLOWED: "false"
      IP_HEADER: "CF-Connecting-IP"
      EXPERIMENTAL_CLIENT_FEATURE_FLAGS: "ssh-key-vault-item,ssh-agent"
    volumes:
      - ./log:/data/log
      - ./vw-data:/data
networks:
  traefik:
    external: true   
```


cloudflare.tunnel.enable will be set to true to enable dockflare management

cloudflare.tunnel.hostname will be the host we configured in traefik's config.yml file to be used publicly. so it was vaultwarden.geniehome.net

and the last label is cloudflare.tunnel.service, which will be the internal host that was configured in traefik's config.yml file. vault.traefik.geniehome.net
