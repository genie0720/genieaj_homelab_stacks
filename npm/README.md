## create npm network
Before starting container, create the npm docker network:
```
sudo docker network create npm
```
start the container:
```
sudo docker compose up -d
```

## First Time Login

When you first go to the admin page, you'll need to use the default email address and password to log in.

email
```
admin@example.com
```
password
```
changeme
```

## ssl certificate
Configure an SSL certificate, tab over to SSL Certficates, click add. 

For the domain name, use a wildcard, or astrick domain. This is so one SSL certificate can be used for multiple hosts. 

The root domain should be your domain that you've brought. ie: *.subdomain.mydomain.net

Add your lets encrypt email and select use a DNS challenge. 

Select Cloudflare. 

For the credentials file content, add your API Token that you've created.

## Cloudflare API Token

Once you log into cloudflare, go to your profile, then api tokens.

click create token.

Chose custom token, then fill out token name

For permissions: zone, zone, read

add another permission: zone, dns, edit

zone resources, choose specific zone, then your root domain. 

click continue to summary

and create token.

make sure to copy the token and paste it in credentials file content.

## Configure Proxy Hosts


Under host, proxy hosts, click on add proxy host

Domain name: some_service.npm.geniehome.net

choose the correct scheme for your service

forward hostname/ip: put the container name for the service running if on the same docker network as NPM. Otherwise you'll use IP address. 

forward port: Port that service is listening on


tab over to SSL and select the SSL certificate that was configured.

click save.

### Pihole specific Configuration
Specific for pihole, you need to go to the advanced tab and add this line of code to be redirected to /admin when access pihole. 

```
location = / {
  return 301 /admin;
}
```

## Authentik Setup

click on the admin interface, and go to applications and create with provider. 

give it a name and click next

chose proxy provider and next

Select an authorization flow

select forward auth single application

for external host, put the url of the service configured. https://some_service.npm.geniehome.net


and chose the token validity and click next

click next again

and submit

add the created application to the embedded outpost 

click on outposts

edit and chose the application created for your service

and click the single arrow to place it over to selected applications and click update

## Authentik Configuration for Proxy Host

click on the 3 little dots of the proxy host you created for your sevice and select edit and tab over to the advanced tab

add block of code thats from the official authentik website.

only need to change proxy_pass under the second location block. proxy_pass url is the url to your authentik instance. If authentik is using the same docker network as NPM, put the container name, and the port 9000. ie: http://container_name_for_authentik:9000/outpost.goauthentik.io

Otherwise you'll use the IP address of your authentik instance.


```

#Increase buffer size for large headers
# This is needed only if you get 'upstream sent too big header while reading response
# header from upstream' error when trying to access an application protected by goauthentik
proxy_buffers 8 16k;
proxy_buffer_size 32k;

# Make sure not to redirect traffic to a port 4443
port_in_redirect off;

location / {
    # Put your proxy_pass to your application here
    proxy_pass          $forward_scheme://$server:$port;
    # Set any other headers your application might need
    # proxy_set_header Host $host;
    # proxy_set_header ...

    ##############################
    # authentik-specific config
    ##############################
    auth_request     /outpost.goauthentik.io/auth/nginx;
    error_page       401 = @goauthentik_proxy_signin;
    auth_request_set $auth_cookie $upstream_http_set_cookie;
    add_header       Set-Cookie $auth_cookie;

    # translate headers from the outposts back to the actual upstream
    auth_request_set $authentik_username $upstream_http_x_authentik_username;
    auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
    auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
    auth_request_set $authentik_email $upstream_http_x_authentik_email;
    auth_request_set $authentik_name $upstream_http_x_authentik_name;
    auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

    proxy_set_header X-authentik-username $authentik_username;
    proxy_set_header X-authentik-groups $authentik_groups;
    proxy_set_header X-authentik-entitlements $authentik_entitlements;
    proxy_set_header X-authentik-email $authentik_email;
    proxy_set_header X-authentik-name $authentik_name;
    proxy_set_header X-authentik-uid $authentik_uid;

    # This section should be uncommented when the "Send HTTP Basic authentication" option
    # is enabled in the proxy provider
    # auth_request_set $authentik_auth $upstream_http_authorization;
    # proxy_set_header Authorization $authentik_auth;
}

# all requests to /outpost.goauthentik.io must be accessible without authentication
location /outpost.goauthentik.io {
    # When using the embedded outpost, use:
    proxy_pass              http://authentik:9000/outpost.goauthentik.io;
    # For manual outpost deployments:
    # proxy_pass              http://outpost.company:9000;

    # Note: ensure the Host header matches your external authentik URL:
    proxy_set_header        Host $host;

    proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
    add_header              Set-Cookie $auth_cookie;
    auth_request_set        $auth_cookie $upstream_http_set_cookie;
    proxy_pass_request_body off;
    proxy_set_header        Content-Length "";
}

# Special location for when the /auth endpoint returns a 401,
# redirect to the /start URL which initiates SSO
location @goauthentik_proxy_signin {
    internal;
    add_header Set-Cookie $auth_cookie;
    return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
    # For domain level, use the below error_page to redirect to your authentik server with the full redirect path
    # return 302 https://authentik.company/outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
}
```
