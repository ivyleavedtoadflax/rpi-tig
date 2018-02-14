# TIG stack for Monitoring IoT devices on Raspberry Pi

## Comprises:

* MQTT broker
* telegraf instance
* influxdb instance
* grafana instance

## Requirements

* A raspberry pi with debian stretch lite.
* Docker [`curl -sSL https://get.docker.com | sh`](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/)
* Future versions will require docker compose, but this version can currently be executed with docker and a makefile.

## Getting started

* Set the following env vars:

|Container|Variable|Description|
|---|---|---|
|telegraf|MQTT_HOST|Local IP address, assuming you are running the mqtt broker locally (e.g. 192.168.1.177)|
|telegraf|MQTT_PORT|Typically 1883|
|telegraf|MQTT_TOPIC|Topic to look for messages (currently just one)|
|telegraf|MQTT_USERNAME|Username requried by the broker|
|telegraf|MQTT_PASSWORD|Password required by the broker|
|telegraf|DATABASE|Influxb database in which to store mqtt messages|
|telegraf|INFLUXDB_HOST|Typically local IP, assuming that the influxdb database is being run locally|
|telegraf|INFLUXDB_PORT|Typically 8086|

* Create `sudo mkdir /data` to create a directory to be used for volume storage.
* Run `make all`.
* To stop and remove containers run `make clean`
