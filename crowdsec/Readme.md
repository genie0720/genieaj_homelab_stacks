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

## **Getting the CrowdSec Bouncer Key for Caddy**

Next, run the 'cscli' (CrowdSec CLI) command inside the CrowdSec container:
```bash
sudo docker exec -it crowdsec cscli
```
### Convenience Tip: Adding an Alias
For ease of use, you can add an alias for `cscli` in your `.bashrc` file:
```
alias cscli="docker exec -it crowdsec cscli"
```
Save the file and reload the alias with:
```bash
source ~/.bashrc
```
Alternatively, restart the terminal.

Run the following command to generate a bouncer key for Caddy:
```bash
cscli bouncers add caddy
```

## **Updating the Caddyfile**

Within your Caddyfile, add the following configuration under the global configuration section:
```
order crowdsec before respond
```
- Ensures that the CrowdSec module processes requests and can block malicious requests before any responses are sent.

## **CrowdSec Block Configuration**

### Adding CrowdSec to Your App
At the bottom of the Caddyfile, add CrowdSec to the app being tested (e.g., PhotoPrism).
- **URL**: Specifies where the CrowdSec API is accessible.
- **API Key**: Used to authenticate with the CrowdSec API.
- **Ticker Interval**: Defines how frequently the CrowdSec middleware checks for updates (e.g., every 3 seconds).
- **APPsec Module**: Handles advanced security and application-level protections.

### Adding CrowdSec to Your App
At the bottom of the Caddyfile, add CrowdSec to the app being tested (e.g., PhotoPrism).

## Restart Caddy Container
Save the changes to the Caddyfile and restart the Caddy container with the following command:
```bash
docker compose up -d --force-recreate
```


