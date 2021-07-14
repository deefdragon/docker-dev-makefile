all:
	@echo go to http://localhost:8089
	docker-compose up

up:
	docker-compose up -d
	@echo go to http://localhost:8089
down:
	docker-compose down
restart:
	docker-compose down
	docker-compose up -d 
swarm:
	docker-compose up -d --scale worker=10

image: 
	docker build . -t mylocust