FROM bitnami/jmx-exporter:latest

COPY jmx-exporter/kafka-jmx.yml /etc/jmx-exporter/config.yml

CMD ["5556", "/etc/jmx-exporter/config.yml"]