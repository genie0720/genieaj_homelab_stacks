## Official Documentation
https://docs.ntfy.sh/config/

## Docker Compose

start the container by running the command 

```
docker compose up -d
```



## Configuring Users 

To run commands inside the ntfy container, run the following command to create an interactive session:
```
docker exec -it ntfy /bin/sh
```
once inside the interactive session, run the following command to create a user named admin and a user named crowdsec:

```
ntfy user add --role=admin admin
ntfy user add crowdsec
``` 
then you can run to show the list of users created :
```
ntfy user list
```
The role admin by default allows the user to read/write any topic. 

## Creating Authentication Tokens

 Run the following command to create a token for user 'crowdsec':

```
ntfy token add crowdsec
```

this will create a token that never expires.

If you want to create a token that expires, just add:

```
ntfy token add --expires=3d crowdsec
```

List tokens created: 

```
ntfy token list
```

Use the following command to modify topic permissions for user crowdsec: 

```
ntfy access crowdsec crowdsec_alerts write-only
```

The command will give user crowdsec write-only permissions for the topic "crowdsec_alerts"

## Creating Topics
To create a topic, all you have to do is click subscribe to topic. Then just type in the name of the topic you want to create. 

Authenticated Curl command to push notifications:

(the authorization header is bearer + the token created.)

```
curl -H "Authorization: Bearer {token_example}" -d "this is a test" https://url/crowdsec_alerts
```

## Auth Parameter

The value of the auth parameter is the value of the authorization header, bearer + user token,  raw base64 encoded

Run the following command on linux distros to get auth parameter:

```
echo -n "Bearer {token}" | base64 | tr -d '='
```


Powershell command:

```
[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("Bearer {token}")) -replace "="
```

Curl command with auth parameter:

```
curl -d "this is a test number 2" https://url/crowdsec_alerts?auth={base64_encoded_token}
```
## Configuring Crowdsec to notify 

Configure Crowdsec to send notifications when a decision was made to block an IP. 

Add the file ntfy.yaml under Crowdsec config/notifications.

Within the file ntfy.yaml, change the URL. 

Restart the Crowdsec Container:

```
docker compose up -d --force-recreate.
```

Run the command to test if the notification service is working:

```
sudo docker exec crowdsec cscli notifications test ntfy. 
```


