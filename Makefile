PWD = $(shell pwd)

all: telegraf.conf telegraf weather.conf weather mqtt influxdb grafana
nuke: clean_docker nuke_data

install_crontab: /etc/cron.d/speedtest

/etc/cron.d/speedtest: templates/crontab.template
	sudo cp $< $@

.env: .envrc
	sed -e "/export/!d" -e "s/export //g" $< > $@ 

test_speed:
	sudo docker-compose up speedtest

configs: grafana.ini telegraf.conf weather.conf

grafana.ini: templates/grafana.template.ini .envrc Makefile
	@ echo "Creating $@ from $<"
	sed -e "s/\$${PGUSER}/$(PGUSER)/" \
		-e "s/\$${PGPASSWORD}/$(PGPASSWORD)/" \
		-e "s/\$${PGHOST}/$(PGHOST)/" \
		-e "s/\$${PGPORT}/$(PGPORT)/" \
		-e "s/\$${PGDATABASE}/$(PGDATABASE)/" \
		$< > $@

telegraf.conf: templates/telegraf.template.conf .envrc Makefile
	echo "Creating $@ from $<"; \
		sed -e "s%\$${MQTT_HOST}%$(MQTT_HOST)%" \
		-e "s/\$${MQTT_PORT}/$(MQTT_PORT)/" \
		-e "s%\$${MQTT_TOPIC}%$(MQTT_TOPIC)%" \
		-e "s/\$${MQTT_USERNAME}/$(MQTT_USERNAME)/" \
		-e "s/\$${MQTT_PASSWORD}/$(MQTT_PASSWORD)/" \
		-e "s/\$${DATABASE}/$(DATABASE)/" \
		-e "s%\$${INFLUXDB_HOST}%$(INFLUXDB_HOST)%" \
		-e "s/\$${INFLUXDB_PORT}/$(INFLUXDB_PORT)/" \
		-e "s/\$${ROUTER_IP}/$(ROUTER_IP)/" \
		-e "s/\$${ELEC_LOCAL_IP}/$(ELEC_LOCAL_IP)/" \
		$< > $@

weather.conf: templates/weather.template.conf .envrc Makefile
	echo "Creating $@ from $<"; \
		sed -e "s/\$${WEATHER_DATABASE}/$(WEATHER_DATABASE)/" \
        -e "s%\$${INFLUXDB_HOST}%$(INFLUXDB_HOST)%" \
        -e "s/\$${INFLUXDB_PORT}/$(INFLUXDB_PORT)/" \
        -e "s%\$${API_ENDPOINT}%$(API_ENDPOINT)%" \
        -e "s/\$${API_KEY}/$(API_KEY)/" \
        -e "s/\$${LON0}/$(LON0)/" \
        -e "s/\$${LAT0}/$(LAT0)/" \
        -e "s/\$${LON1}/$(LON1)/" \
        -e "s/\$${LAT1}/$(LAT1)/" \
        -e "s/\$${LON2}/$(LON2)/" \
        -e "s/\$${LAT2}/$(LAT2)/" \
        -e "s/\$${WEATHER_INTERVAL}/$(WEATHER_INTERVAL)/" \
		$< > $@

weather:
	sudo docker run \
	--log-opt max-size=${LOG_SIZE} \
        -d --restart unless-stopped \
        -v $(PWD)/weather.conf:/etc/telegraf/telegraf.conf:ro \
        --name weather \
        -it telegraf:latest

mqtt:
	sudo docker run -ti -p 1883:1883 \
	--log-opt max-size=${LOG_SIZE} \
	-v /data/mqtt/config:/mqtt/config:ro \
	-v /data/mqtt/log:/mqtt/log \
	-v /data/mqtt/data:/mqtt/data/ \
	 --restart unless-stopped \
	 --name mqtt -d pascaldevink/rpi-mosquitto

clean:
	-sudo docker stop influxdb
	-sudo docker rm influxdb
	-sudo docker stop telegraf
	-sudo docker rm telegraf
	-sudo docker stop grafana
	-sudo docker rm grafana
	-sudo docker stop mqtt
	-sudo docker rm mqtt
	-sudo docker stop weather
	-sudo docker rm weather

nuke_data:
	-sudo rm -r /data/grafana /data/influx /data/telegraf

test_mqtt:
	mosquitto_sub -h $(MQTT_HOST)  -p $(MQTT_PORT) \
	-u $(MQTT_USERNAME) -t "#"
	#-P $(MQTT_PASSWORD) -t '#' 

influxdb_latest:
	sudo docker exec -it influxdb influx \
	-precision rfc3339 -database $(DATABASE) \
	-execute "select last(Pulses) as Pulses, Cost, Night, \
	time from /.*/"

help:
	@cat Makefile

.PHONY: clean test_mqtt influxdb_latest nuke_data clean help
