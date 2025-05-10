## Traefik Without Labels
Official Traefik Documentation - https://doc.traefik.io/traefik/getting-started/install-traefik/r

### create traefik docker network

```
sudo docker network create traefik
```

### Create Data Directory

```
mkdir data
```

inside data directory, create the following files:

```
touch acme.json config.yml traefik.yml
```


### traefik.yml

```
api:
  dashboard: true
  debug: true
entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"
serversTransport:
  insecureSkipVerify: true
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    filename: /config.yml
certificatesResolvers:
  cloudflare:
    acme:
      email: email@email.com # your cloudflare email
      storage: acme.json
      caServer: https://acme-v02.api.letsencrypt.org/directory # prod (default)
      #caServer: https://acme-staging-v02.api.letsencrypt.org/directory # staging
      dnsChallenge:
        provider: cloudflare
        #disablePropagationCheck: true # uncomment this if you have issues pulling certificates through cloudflare, By setting this flag to true disables the need to wait for the propagation of the TXT record to all authoritative name servers.
        #delayBeforeCheck: 60s # uncomment along with disablePropagationCheck if needed to ensure the TXT record is ready before verification is attempted
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
log:
  level: "INFO"
  filePath: "/var/log/traefik/traefik.log"
accessLog:
  filePath: "/var/log/traefik/access.log"
  format: "json"
  bufferingSize: 100
  fields:
    defaultMode: keep
    headers:
      defaultMode: keep
      names:
        "X-Forwarded-For": keep
        "CF-Connecting-IP": keep
```


### config.yml

```
http:
  routers:
    traefik-secure:
      entryPoints:
        - "https"
      rule: "Host(`dashboard.traefik.subdomain.net`)"
      middlewares:
        - primary
      tls:
        certResolver: "cloudflare"
        domains:
          - main: "traefik.subdomain.net"
            sans: "*.traefik.subdomain.net"
      service: api@internal
      
    vaultwarden:
      entryPoints:
        - "https"
      rule: "Host(`vault.traefik.subdomain.net`)"
      middlewares:
        - primary
      tls: {}
      service: vaultwarden
      
    photoprism:
      entryPoints:
        - "https"
      rule: "Host(`photoprism.traefik.subdomain.net`)"
      middlewares:
        - primary
      tls: {}
      service: photoprism

  services:

    vaultwarden:
      loadBalancer:
        servers:
          - url: "http://vaultwarden"
        passHostHeader: true
        
    photoprism:
      loadBalancer:
        servers:
          - url: "http://photoprism:2342"
        passHostHeader: true


  middlewares:

    example-ipwhitelist:
      ipAllowList:
        sourceRange:
          - "192.168.8.0/27"

    https-redirect:
      redirectScheme:
        scheme: https

    default-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 15552000
        customFrameOptionsValue: SAMEORIGIN
        customRequestHeaders:
          X-Forwarded-Proto: https

    primary:
      chain:
        middlewares:
        - default-headers
        - https-redirect
        - geniehome-ipwhitelist
```

### .env file

```
CF_DNS_API_TOKEN=cloudflare_api_token
TRAEFIK_DASHBOARD_CREDENTIALS=whatever_password
```

Within the .env file we need to add two variables, the cloudflare api token, and the traefik dashboard credentials.


### Dashboard Credentials

Use htpasswd. if you dont have the tool, you can install it using this command 

```
sudo apt update 
sudo apt install apache2-utils
```

Run the following command to generate the credential and paste it into the .env: you can change admin to whatever username you want. 

```
echo "TRAEFIK_DASHBOARD_CREDENTIALS=$(echo $(htpasswd -nB admin) | sed -e s/\\$/\\$\\$/g)" >> .env
```

now we can finally start the container by running the command 
```
sudo docker compose up -d
```
