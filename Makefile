PWD = $(shell pwd)

all: configs

install_crontab: /etc/cron.d/rpi-tig

/etc/cron.d/rpi-tig: templates/crontab.template
	sudo cp $< $@

.env: .envrc
	sed -e "/export/!d" -e "s/export //g" $< > $@ 

.PHONY: test_speed
test_speed:
	sudo docker-compose up speedtest

# Populate configs with environment variables

configs: grafana.ini telegraf.conf weather.conf mosquitto.conf

mosquitto.conf: templates/mosquitto.template.conf .envrc Makefile
	@ echo "Creating $@ from $<"
	#sed -e "s/\$${PGUSER}/$(PGUSER)/" \
	#	-e "s/\$${PGPASSWORD}/$(PGPASSWORD)/" \
	#	-e "s/\$${PGHOST}/$(PGHOST)/" \
	#	-e "s/\$${PGPORT}/$(PGPORT)/" \
	#	-e "s/\$${PGDATABASE}/$(PGDATABASE)/" \
	#	$< > $@
	cp $< $@

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
		-e "s%\$${WEBSITE_0}%$(WEBSITE_0)%" \
		-e "s%\$${WEBSITE_1}%$(WEBSITE_1)%" \
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

.PHONY: down
down:
	sudo docker-compose down

.PHONY: up
up: configs .env
	sudo docker-compose up -d

.PHONY: nuke_data
nuke_data:
	-sudo rm -r /data/grafana /data/influx /data/telegraf

.PHONY: test_mqtt
test_mqtt:
	mosquitto_sub -h $(MQTT_HOST)  -p $(MQTT_PORT) \
	-u $(MQTT_USERNAME) -t "#"
	#-P $(MQTT_PASSWORD) -t '#' 

.PHONY: influxdb_latest
influxdb_latest:
	sudo docker exec -it influxdb influx \
	-precision rfc3339 -database $(DATABASE) \
	-execute "select last(Pulses) as Pulses, Cost, Night, \
	time from /.*/"

.PHONY: help
help:
	@cat Makefile

