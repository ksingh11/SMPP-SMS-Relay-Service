
# Sms-Server on SMPP
A SMPP protocol based SMS server. Which exposes a HTTP api endpoint, to trigger SMS through SMPP protocol.
Maintains a queue of messages, and process messages from the queue in background and relays further through SMPP.

## API Endpoint
```
GET /api/v1/send-message/?phone=<PHONE NUMBER>&msg=<MESSAGE TEXT>
HTTP/1.1
Host: localhost:4000
client_id: zostel
client_key: hello123
```
Specifications:

>PHONE NUMBER: International format, without (+). eg. 919839098390
>HTTP Headers:
>	- client_id
>	- client_key

## Installation
```
$ git clone <repository>
$ mix deps.get
$ mix deps.compile
$ MIX_ENV=prod mix distillery.release
$ _build/prod/rel/sms_server/bin/sms_server start

# Stop server
$ _build/prod/rel/sms_server/bin/sms_server stop

# Attach shell to server
$ _build/prod/rel/sms_server/bin/sms_server remote_console

# Database migration
$ _build/prod/rel/sms_server/bin/sms_server migrate
```
Dependencies:
```
- RabbitMQ Server
- Postgresql server
- Elixir 1.9
```

  **Webserver Environment variables:**
  ```
 HTTP_PORT, default: 4000
 ```
  **Database Environment variables:**
```
DB_DATABASE, default: sms_server
DB_USERNAME, default: postgres
DB_PASSWORD, default: postgres
DB_HOSTNAME, default: localhost
```
**RabbitMQ  Environment variables:**
```
AMQP_HOST, default: "amqp://kbadmin:s7****es@localhost:5672/khatabook"
AMQP_CHANNEL, default: kb_channel
```
  
**SMPP Environment variables:**
```
SMPP_HOST, default: "smsc-sim.smscarrier.com",
SMPP_PORT, default: 2775
SMPP_USER, default: "test"
SMPP_PASS, default: "test"
```

## Database Setup
Specifications:

>Create Database: sms_server
>Run Migration
>Table: apikey
>Fields: client_id, client_key, sender
>Eg.:
>```
>client_id: zo_client
>client_key: fycz31qo
>sender: ZONOTIF (sender ID for the SMS)
>```