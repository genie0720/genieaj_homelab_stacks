# Vaultwarden Tutorial
https://github.com/dani-garcia/vaultwarden

## Docker Compose

### couple of things to note: 
you can only access Vaultwarden with a valid ssl certificate and a reverse proxy to handle HTTPS. 

Before starting the container, create the admin token for the .env file so that the admin dashboard can be accessible. This is optional. 

The admin token is an Argon2 hash, which is a secure password hashing algorithm designed to protect against brute-force attacks and ensure strong cryptographic security.

Make sure you have argon2 installed.

```
sudo apt update && sudo apt install -y argon2
```

Command to hash your password and store it in the .env file:

```
echo "ADMIN_TOKEN='$(echo -n 'password123' | argon2 $(openssl rand -base64 16) -k 65536 -t 4 -p 2 -e)'" >> .env
```

Start the container by running the command: 

```
docker compose up -d
```



## Configuring Users 
URL to download device clients:

```
https://bitwarden.com/download/
``` 

## SSH Agent Configuration 

Generate a ssh key using new item - ssh key in the Vaultwarden UI.

*For Windows

disable the openssh service that windows uses by default. 

- Check the status of the SSH-Agent service
```
Get-Service -Name ssh-agent
```
- Stop the SSH-Agent service if it is running
```
Stop-Service -Name ssh-agent
```
- Disable the SSH-Agent service
```
Set-Service -Name ssh-agent -StartupType Disabled
```
Enable ssh-agent in the Bitwarden desktop app under File - Settings

Test to see if the ssh agent is working as expected, open a powershell terminal and run the following command to list available ssh keys:

```
ssh-add -L
```
## adding public key to server
Add the public key to the server you want to authenticate via ssh keys.
Log into server and run the following command:
```
echo "public-ssh-key" >> ~/.ssh/authorized_keys
```

## Admin panel

GO to  /admin to access the admin panel.
