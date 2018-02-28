PWD = $(shell pwd)
GRAFANA_VERSION=3.1.1

all: telegraf.conf telegraf weather.conf weather mqtt influxdb grafana
nuke: clean_docker nuke_data

telegraf.conf: telegraf.template.conf .envrc
	echo "Creating telegraf.conf file"; \
	sed -e "s%\$${MQTT_HOST}%$(MQTT_HOST)%" \
	-e "s/\$${MQTT_PORT}/$(MQTT_PORT)/" \
	-e "s%\$${MQTT_TOPIC}%$(MQTT_TOPIC)%" \
	-e "s/\$${MQTT_USERNAME}/$(MQTT_USERNAME)/" \
	-e "s/\$${MQTT_PASSWORD}/$(MQTT_PASSWORD)/" \
	-e "s/\$${DATABASE}/$(DATABASE)/" \
	-e "s%\$${INFLUXDB_HOST}%$(INFLUXDB_HOST)%" \
	-e "s/\$${INFLUXDB_PORT}/$(INFLUXDB_PORT)/" \
	telegraf.template.conf > telegraf.conf

weather.conf: weather.template.conf .envrc
	echo "Creating weather.conf file"; \
        sed -e "s/\$${WEATHER_DATABASE}/$(WEATHER_DATABASE)/" \
        -e "s%\$${INFLUXDB_HOST}%$(INFLUXDB_HOST)%" \
        -e "s/\$${INFLUXDB_PORT}/$(INFLUXDB_PORT)/" \
        -e "s%\$${API_ENDPOINT}%$(API_ENDPOINT)%" \
        -e "s/\$${API_KEY}/$(API_KEY)/" \
        -e "s/\$${LON}/$(LON)/" \
        -e "s/\$${LAT}/$(LAT)/" \
        -e "s/\$${WEATHER_INTERVAL}/$(WEATHER_INTERVAL)/" \
        weather.template.conf > weather.conf

grafana:
	sudo docker run -t -d --name=grafana \
        -p 3000:3000 \
	-d --restart unless-stopped \
        -v /data/grafana/etc_grafana:/etc/grafana \
        -v /data/grafana/data:/data \
        heziegl/rpi-grafana:$(GRAFANA_VERSION)

telegraf:
	sudo docker run \
	-d --restart unless-stopped \
	-v $(PWD)/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-v /data/speedtest:/data/speedtest \
	--name telegraf \
	-it telegraf:latest

weather:
	sudo docker run \
        -d --restart unless-stopped \
        -v $(PWD)/weather.conf:/etc/telegraf/telegraf.conf:ro \
        --name weather \
        -it telegraf:latest

influxdb:
	sudo docker run \
	-v /data/influxdb:/var/lib/influxdb \
	-v /data/influxdb/backup:/data/influxdb/backup \
	-d --restart unless-stopped \
	-p 8086:8086 --name influxdb \
	-it influxdb:latest

mqtt:
	sudo docker run -ti -p 1883:1883 \
	-v /data/mqtt/config:/mqtt/config:ro \
	-v /data/mqtt/log:/mqtt/log \
	-v /data/mqtt/data:/mqtt/data/ \
	 --restart unless-stopped \
	 --name mqtt -d pascaldevink/rpi-mosquitto

clean:
	-sudo docker stop influxdb && \
	sudo docker rm influxdb; \
	sudo docker stop telegraf && \
	sudo docker rm telegraf;
	sudo docker stop grafana && \
	sudo docker rm grafana
	sudo docker stop mqtt && \
	sudo docker rm mqtt

nuke_data:
	-sudo rm -r /data/grafana /data/influx /data/telegraf

test_mqtt:
	mosquitto_sub -h $(MQTT_HOST)  -p $(MQTT_PORT) \
	-u $(MQTT_USERNAME) -P $(MQTT_PASSWORD) -t '#' 

influxdb_latest:
	sudo docker exec -it influxdb influx \
	-precision rfc3339 -database $(DATABASE) \
	-execute "select last(Pulses) as Pulses, Cost, Night, \
	time from /.*/"

help:
	@cat Makefile

.PHONY: clean test_mqtt influxdb_latest nuke_data clean help
