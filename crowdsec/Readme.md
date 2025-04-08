# CrowdSec Docker Compose

## **CrowdSec Docker Compose Setup**

### Overview
First, we will review the Docker Compose file for CrowdSec:
- **Service Configuration**: Under `services`, we configure a service named `crowdsec`.
- **Image**: The latest version of the official CrowdSec image is used.
- **Container Name**: Set as `crowdsec`.
- **Environment Variables**: Specify the collections for CrowdSec to download.
  - **Collections**: Curated bundles of parsers, scenarios, and postoverflows designed for specific security use cases, such as protecting web servers or detecting brute-force attacks.
  - **Required Collections for this setup**: 
    - `linux`
    - `caddy`
    - `appsec-generic-rules`
    - `appsec-virtual-patching`

### Volumes
Ensure that access to Caddy logs is included:
- Create a configuration directory and add `acquis.yaml` to it.

### Networks
- Place CrowdSec within the same network as Caddy.

### Restart Policy
- Set to restart unless manually stopped.

### Networks Section
- The Caddy network must be externally created.

### Starting the CrowdSec Container
Run the following command:
```bash
sudo docker compose up -d
```
### Checking container logs
Run the following command:
```bash
sudo docker logs crowdsec
```
