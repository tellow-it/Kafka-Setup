help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  run - Run the development environment"
	@echo "  stop - Stop the development environment"
	@echo "  clean - Clean up the development environment"

build:
	sudo docker build -t kafka-jmx-exporter . 

run:
	sudo docker compose -f docker-compose.dev.yml up -d

stop:
	sudo docker compose -f docker-compose.dev.yml down

clean:
	sudo docker compose -f docker-compose.dev.yml down -v --remove-orphans