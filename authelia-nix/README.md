## Setup Immich OpenID Connect with Authelia

### Prerequisites

I use flakes in my setup

Add this to your configuration.nix file
```
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

You'll also want to add the `authelia` binary to your environment.systempackages. Authelia binary will be used to generate secrets.

And then you may need to add port 9091 to allowed tcp ports

```
networking.firewall.allowedTCPPorts = [ 9091 ];
```

Authelia’s web UI runs on port  9091 by default.

Traefik. I use Traefik as my reverse proxy across all my services.

```
 https://github.com/genie0720/genieaj_homelab_stacks/tree/main/traefik_coreDNS_Jellyfin
```

## Configuring Secrets

### JWKS Key

Generate the JWKS key that Authelia will use to sign its OpenID Connect tokens

```
https://www.authelia.com/reference/guides/generating-secure-values/#generating-an-rsa-keypair
```

you can create the JWKS key by simply running this command 

```
authelia crypto pair rsa generate
```

This will generate a new RSA key pair in your current directory:
• 	private.pem: the private key you’ll paste into your  authelia.nix module.
• 	public.pem: the public key clients can use to verify tokens.
You can also pass flags like --directory  to control where the files are saved, but by default it’ll drop them right where you run the command.

### Jwt and Storage Encryption key file

```
https://www.authelia.com/reference/guides/generating-secure-values/#generating-a-random-alphanumeric-string
```

Generate the JWT secret and the storage encryption key.

First, create the authelia directory.

```
sudo mkdir -p /etc/authelia
```

command:

```
authelia crypto rand --length 64 --charset alphanumeric | awk '{print $NF}' | sudo tee /etc/authelia/jwt_secret.txt > /dev/null
authelia crypto rand --length 64 --charset alphanumeric | awk '{print $NF}' | sudo tee /etc/authelia/encryption_key.txt > /dev/nul
```

This generates a secure, 64-character alphanumeric string.

### HMAC Key

generate the hmac_secret

```
authelia crypto rand --length 64 --charset alphanumeric
```

copy the output string and paste it directly into your authelia module:

### Client ID/ Secret

```
https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#how-do-i-generate-a-client-identifier-or-client-secret
```

Create a client ID and client secret for each service we want to integrate.

generate the client id using this command 

```
authelia crypto rand --length 72 --charset rfc3986
```

Copy the output and paste it into your NixOS module under client ID.

generate the client secret by running this command that creates a secure random password and hash using PBKDF2 with SHA-512

```
authelia crypto hash generate pbkdf2 --variant sha512 --random --random.length 72 --random.charset rfc3986
```

You’ll get two outputs:
• 	random password: This is the plaintext password you’ll use when configuring Proxmox to authenticate via Authelia.
• 	Digest: This is the hashed secret you’ll paste into your NixOS module:

Make sure to keep the plaintext password safe.It's only shown once and needed by the client during setup.

Each service gets its own unique client ID and secret pair.

## User database

```
www.authelia.com/reference/guides/passwords/
```

create the file in the /etc/authelia directory.


`password` :  This is a hashed password using Argon2id. You can generate it with:

```
authelia crypto hash generate argon2 --password 'yourpassword'
```

## Start Service

Within `configuration.nix`,

 import the authelia.nix module:

Once that’s in place, run:

```
sudo nixos-rebuild switch --flake .#
```

Once its built, Authelia will be activated, but the service will likely fail on first start
You can check the status with:

```
systemctl status authelia-test.service
```

And dig into the logs with:

```
journalctl -u authelia-test.service -xe
```

This happens because the `authelia` system user and group don’t exist until the service is started for the first time. Once that happens, you can fix the file ownership.

```
sudo chown authelia-test:authelia-test /etc/authelia/jwt_secret.txt /etc/authelia/encryption_key.txt
sudo chmod 640 /etc/authelia/jwt_secret.txt /etc/authelia/encryption_key.txt
```

After that, restart the service:

```
sudo systemctl restart authelia-test.service
```

Now Authelia should start cleanly and be able to read its secrets.

## Initial Setup

Go to the Authelia homepage and log in using the user we configured earlier.

Once you're logged in, Authelia will prompt you to register a device for two-factor authentication. Click ‘Register Device’, and you’ll be given two options: a One-Time Password (OTP) or WebAuthn credentials.

When you click ‘Add’, Authelia will ask to verify your identity by sending a one-time code to your email. But in our setup, remember—we configured Authelia to write notifications to a local file instead of sending real emails.

That file is located at:

```
/var/lib/authelia-test/notifications.txt
```

So let’s grab the code by running:

```
sudo cat /var/lib/authelia-test/notifications.txt
```

Copy the code from that file, paste it into the verification prompt, and now we can register our OTP device.


## Immich OpenID Connect

configure Immich to use Authelia as its OpenID Connect provider.

Log into Immich, click your profile picture, and head to **Administration**. From there, go to **Settings → Authentication Settings → OAuth**.

Click **‘Login with OAuth’**, and fill out the following fields:

- **Issuer URL**: This tells Immich where to find Authelia’s OIDC metadata. Use:

```
https://authelia.test.geniehome.net/.well-known/openid-configuration
```

- **Client ID**: This is the value we generated earlier for Immich. You’ll find it in your `authelia.nix` module.
  
- **Client Secret**: This is the **unhashed password** we generated alongside the digest.

- **Scope**: Set this to:

```
openid email profile
```

- **ID Token Signed Response Algorithm**: `RS256`
   **Userinfo Signed Response Algorithm**: `none`
    
    Everything else can be left at the default values.
    
    If you want Immich to automatically create new users when they log in via Authelia, enable **Auto Register**. Then click **Save**.

### **Linking Authelia to an Existing Immich User**

If you’d rather link Authelia to an existing Immich account:

1. Log in to Immich using your existing username and password.
2. Click your profile picture → **Account Settings**.
3. Go to the **OAuth** section and click **‘Link to OAuth’**.
4. A new page will open with Authelia’s login screen. Authenticate there, and your Authelia identity will be linked to your Immich user.

## Proxy Provider Integration 

```
[Traefik | Integration | Authelia](https://www.authelia.com/integration/proxies/traefik/)
```

In my Traefik Nix module, add this block:

```
authelia.forwardAuth = {
  address = "http://192.168.20.19:9091/api/authz/forward-auth";
  trustForwardHeader = true;
  authResponseHeaders = [
    "Remote-User"
    "Remote-Groups"
    "Remote-Email"
    "Remote-Name"
  ];
};
```

Now we update the router definition for Kuma to use the Authelia middleware:

```
routers.kuma = {
  rule = "Host(`kuma.local.geniehome.net`)";
  entryPoints = [ "websecure" ];
  middlewares = [
    "authelia"
    "default-headers"
    "https-redirect"
    "geniehome-ipwhitelist"
  ];
  service = "kuma";
  tls.certResolver = "cloudflare";
};

services.kuma.loadBalancer = {
  passHostHeader = true;
  servers = [
    { url = "http://192.168.5.4:3001"; }
  ];
};
```
