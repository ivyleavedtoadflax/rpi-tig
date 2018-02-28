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
|telegraf|WEATHER_DATABASE|Tpically `weather`|
|telegraf|WEATHER_INTERVAL|Interval to poll the API: 10m|
|telegraf|API_ENDPOINT|http://api.openweathermap.org/data/2.5/weather|
|telegraf|API_KEY|API key for weather API. Available frm openweathermap.org|
|telegraf|LAT|Latitude for weather measurements|
|telegraf|LON|Longitude for weather measurements|

* Create `sudo mkdir /data` to create a directory to be used for volume storage.
* Run `make all`.
* To stop and remove containers run `make clean`

## Speedtest

Monitoring internet connection speed is handled with the rpi-speedtest-cli image.
A cronjob calls this container at a set interval, and logs the output to json. This json is then read by telegraf using the tail plugin. In order to read this file, an appropriate volume must be mounted to allow the telegraf to read it from the host file system:

```{make}
telegraf:
	sudo docker run \
	-d --restart unless-stopped \
	-v $(PWD)/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-v /data/speedtest:/data/speedtest \
	--name telegraf \
	-it telegraf:latest
```

The following cronjob runs the task every 5 minutes:

```{bash}
*/5 * * * * sudo docker run rpi-speedtest-cli --json >> /data/speedtest/speedtest.json
```

## Backing up the data

Backup jobs are run on the influx database using a cronjob which calls the `influxd backup` command. An appropriate volume must again be specified when creating the influxdb container.

```
* * */5 * * sudo docker exec -it influxdb influxd backup -database telegraf /data/influxdb/backup
```

