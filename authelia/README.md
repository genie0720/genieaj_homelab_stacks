**Official Documention** - https://www.authelia.com/integration/prologue/get-started/

## Secrets

✅ **JWT_SECRET** → Used for verifying password reset requests.

✅ **SESSION_SECRET** → encrypts and signs user sessions, ensuring login data remains **safe and tamper-proof**.

✅ **STORAGE_ENCRYPTION_KEY** → Keeps sensitive user data encrypted in Authelia’s **database**

Run the following command to create the secrets and file


### jwt secret

```
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 > ./secrets/JWT_SECRET
```

### storage encryption key

```
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 > ./secrets/STORAGE_ENCRYPTION_KEY
```

### session secret

```
tr -cd '[:alnum:]' < /dev/urandom | fold -w 64 | head -n 1 > ./secrets/SESSION_SECRET
```


### Password hash for users.yml

user password

```
docker run -v ./configuration.yml:/configuration.yml --rm authelia/authelia:latest authelia crypto hash generate --config /configuration.yml --password 'password123'
```

change 'password123' to whatever password you want the user to have

## traefik.yml configuration 

```
http:
  routers:
    authelia:
      entryPoints:
        - "https"
      rule: "Host(`authelia.subdomain.domain.net`)"
      middlewares:
        - primary
      tls: {}
      service: authelia

services:
  authelia:
    loadBalancer:
      servers:
        - url: "http://authelia:9091" # docker container name + port
      passHostHeader: true

middlewares:
  authelia:
    forwardAuth:
      address: "http://authelia:9091/api/verify?rd=https://authelia.subdomain.domain.net"
      trustForwardHeader: true
      authResponseHeaders:
        - Remote-User
        - Remote-Groups
        - Remote-Name
        - Remote-Email
```
