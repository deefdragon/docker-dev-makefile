SHELL=/bin/bash
IPS:=$(shell hostname -I)
LOCAL_IP:=10.151.125.137
USER=$(shell id -nu)

DOCKER_DATA_DIR=/data/docker

CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

MONGO_PORT=27017
MONGO_EXPRESS_PORT=8087
POSTGRES_PORT=5432
PGADMIN_PORT=8082
REDIS_PORT=6379

INFLUX_PORT=8086
INFLUX_GRAPHITE_PORT=2003
GRAFANA_PORT=8085
CHRONOGRAF_PORT=8084


HEIMDALL_PORT=80
TRAEFIK_PORT=8080
KEYCLOAK_PORT=8090
OPENHAB_PORT=8091
HASSIO_PORT=8123
XOA_PORT=8093

.PHONY: logstash



heimdall:
	docker run -d \
	--restart=unless-stopped \
	--name=heimdall \
	-e PUID=1000 \
	-e PGID=1000 \
	-p 80:80 \
	-p 443:443 \
	-v $(DOCKER_DATA_DIR)/heimdall:/config \
	linuxserver/heimdall

nginx:
	docker run -d \
	--restart=unless-stoppped \
	
mytele:
	docker build -f mytele.dockerfile -t mytele .
telegraf: mytele
	rm $(DOCKER_DATA_DIR)/telegraf/telegraf.conf -rf || true
	mkdir $(DOCKER_DATA_DIR)/telegraf || true
	cp ./telegraf.conf $(DOCKER_DATA_DIR)/telegraf/telegraf.conf

	docker run -d \
	--restart=unless-stopped \
	--privileged \
	--name=telegraf \
	-e HOST_PROC=/hostfs/proc \
	-e HOST_MOUNT_PREFIX=/hostfs \
	-e INFLUX_PORT=$(INFLUX_PORT) \
	-e INFLUX_IP=$(LOCAL_IP) \
	-e INFLUX_WRITE_USERNAME=admin \
	-e INFLUX_WRITE_PASSWORD=password \
	-e INFLUX_READ_USERNAME=admin \
	-e INFLUX_READ_PASSWORD=password \
	-e IPMI_USERNAME=root \
	-e IPMI_PASSWORD=Password1234 \
	-e POSTGRES_READ_USERNAME=admin \
	-e POSTGRES_READ_PASSWORD=password \
	-v $(DOCKER_DATA_DIR)/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-v $(DOCKER_DATA_DIR)/telegraf/tools:/tools:ro \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v /:/hostfs:ro \
	-v /run/udev:/run/udev:ro \
	mytele &

frontend:
	docker run -d \
	--restart=unless-stopped \
	--name=streemfront \
	-p 8080:8183 \
	deefdragon/streemfront

grafana:
	docker run -d \
	--restart=unless-stopped \
	--name=grafana \
	-p $(GRAFANA_PORT):3000 \
	-v $(DOCKER_DATA_DIR)/grafana:/var/lib/grafana \
	grafana/grafana &

chronograf:
	docker run -d \
	--restart=unless-stopped \
	--name chronograf \
	-p $(CHRONOGRAF_PORT):8888 \
	-v $(DOCKER_DATA_DIR)/chronograf/data:/var/lib/chronograf \
	chronograf &

influxdb:
	mkdir $(DOCKER_DATA_DIR)/influxdb || true
	cp ./influxdb.conf $(DOCKER_DATA_DIR)/influxdb/influxdb.conf

	docker run -d \
	--restart=unless-stopped \
	--name influxdb \
	-p $(INFLUX_PORT):8086 \
	-p $(INFLUX_GRAPHITE_PORT):2003 \
	-e INFLUXDB_DB=influx \
	-e INFLUXDB_GRAPHITE_ENABLED=true \
	-e INFLUXDB_ADMIN_USER=admin \
	-e INFLUXDB_ADMIN_PASSWORD=password \
	-e INFLUXDB_USER=grafana \
	-e INFLUXDB_USER_PASSWORD=password \
	-v $(DOCKER_DATA_DIR)/influxdb/data:/var/lib/influxdb \
	-v $(DOCKER_DATA_DIR)/influxdb/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
	influxdb &

mongodb:
	docker run -d \
	--restart=unless-stopped \
	--name mongodb \
	-p $(MONGO_PORT):27017 \
	-e MONGO_INITDB_ROOT_USERNAME=admin \
	-e MONGO_INITDB_ROOT_PASSWORD=password \
	-v $(DOCKER_DATA_DIR)/mongodb/data:/data/db \
	mongo &

express:
	docker run -d \
	--user $(CURRENT_UID):$(CURRENT_GID) \
	--restart=unless-stopped \
	--name express \
	-p $(MONGO_EXPRESS_PORT):8081 \
	-e ME_CONFIG_OPTIONS_EDITORTHEME="material-palenight" \
	-e ME_CONFIG_MONGODB_SERVER="$(LOCAL_IP)" \
	-e ME_CONFIG_BASICAUTH_USERNAME="admin" \
	-e ME_CONFIG_BASICAUTH_PASSWORD="password" \
	-e ME_CONFIG_MONGODB_ADMINUSERNAME="admin" \
	-e ME_CONFIG_MONGODB_ADMINPASSWORD="password" \
	mongo-express &

postgres:
	docker run -d \
	--user $(CURRENT_UID):$(CURRENT_GID) \
	--restart=unless-stopped \
	--name postgres \
	-p $(POSTGRES_PORT):5432 \
	-e POSTGRES_DB=public \
	-e POSTGRES_USER=admin \
	-e POSTGRES_PASSWORD=password \
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v $(DOCKER_DATA_DIR)/postgres:/var/lib/postgresql \
	postgres &


pgadmin:
	docker run -d \
	--restart=unless-stopped \
	--name pgadmin \
	-p $(PGADMIN_PORT):80 \
	-e 'PGADMIN_DEFAULT_PASSWORD=password' \
	-e 'PGADMIN_DEFAULT_EMAIL=admin@admin.net' \
	-v $(DOCKER_DATA_DIR)/pgadmin/pgadmin:/var/lib/pgadmin \
	dpage/pgadmin4:4 &

redis:
	docker run -d \
	--restart=unless-stopped \
	--name redis \
	-e REDIS_PASSWORD=Password1234 \
	-p $(REDIS_PORT):6379 \
	-v $(DOCKER_DATA_DIR)/redis:/bitnami/redis/data \
	bitnami/redis:latest &

keycloak:
	docker run -d \
	--user $(CURRENT_UID):$(CURRENT_GID) \
	--restart=unless-stopped \
	--name keycloak \
	-p $(KEYCLOAK_PORT):8080 \
	-e KEYCLOAK_USER=admin \
	-e KEYCLOAK_PASSWORD=password \
	-e DB_VENDOR=postgres \
	-e DB_USER=admin \
	-e DB_PASSWORD=password \
	-e DB_DATABASE=public \
	-e DB_SCHEMA=keycloak \
	-e DB_ADDR=$(LOCAL_IP) \
	-e DB_PORT=5432 \
	jboss/keycloak &

traefik:
	docker run -d \
	--user $(CURRENT_UID):$(CURRENT_GID) \
	--restart=unless-stopped \
	--name traefik \
	-p 80:80 \
	-p $(TRAEFIK_PORT):8080 \
	-v $(DOCKER_DATA_DIR)/traefik/traefik.yml:/etc/traefik/traefik.yml \
	-v /var/run/docker.sock:/var/run/docker.sock \
	traefik:v2.0 &

openhab:
	docker run -d \
	--restart=unless-stopped \
	--name openhab \
	-p $(OPENHAB_PORT):8080 \
	-e OPENHAB_HTTP_PORT=8080 \
	-e USER_ID=$(CURRENT_UID) \
	-e GROUP_ID=$(CURRENT_GID) \
	-v /etc/localtime:/etc/localtime:ro \
	-v /etc/timezone:/etc/timezone:ro \
	-v $(DOCKER_DATA_DIR)/openhab/conf:/openhab/conf \
	-v $(DOCKER_DATA_DIR)/openhab/userdata:/openhab/userdata \
	-v $(DOCKER_DATA_DIR)/openhab/addons:/openhab/addons \
	openhab/openhab &

hassio:
	docker run --init -d \
	--restart=unless-stopped \
	--name="hassio"  \
	-p $(HASSIO_PORT):8123 \
	-e "TZ=America/New_York"  \
	-v $(DOCKER_DATA_DIR)/hassio:/config  \
	homeassistant/home-assistant:stable &

xoa:
	docker run -d \
	--user $(CURRENT_UID):$(CURRENT_GID) \
	--restart=unless-stopped \
	--name xoa \
	-p $(XOA_PORT):80 \
	-v $(DOCKER_DATA_DIR)/xoa/xo-server:/var/lib/xo-server \
	-v $(DOCKER_DATA_DIR)/xoa/redis:/var/lib/redis \
	ronivay/xen-orchestra &
