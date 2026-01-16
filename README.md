# Task Broker

Брокер задач позволяет построить распределенную систему обработки данных.
Используется в качестве хранилища задач для обработки на сервисах.
Сервисы будут подключаться к очереди, брать задачи на обработку, удалять обработанные задачи из очереди.
Такая система позволит подключиться любое число обработчиков, вне зависимости от CPU это сервер или GPU.

## Описание

Проект представляет собой инфраструктуру брокера задач на базе Apache Kafka для распределенной обработки задач. Включает в себя:

- **Apache Kafka 3.7.0** - брокер сообщений для управления очередями задач
- **Kafka UI** - веб-интерфейс для просмотра состояния брокера и администрирования
- **JMX Exporter** - экспорт метрик Kafka для мониторинга

## Требования

- Docker и Docker Compose
- Make (опционально, для удобства использования)

## Структура проекта

```
.
├── docker-compose.yml          # Production конфигурация
├── docker-compose.dev.yml      # Development конфигурация
├── docker-compose.test.yml     # Test конфигурация
├── Dockerfile                  # Dockerfile для сборки образа JMX Exporter
├── .gitlab-ci.yml              # CI/CD конфигурация для GitLab
├── Makefile                    # Команды для управления окружением
├── jmx-exporter/
│   └── kafka-jmx.yml          # Конфигурация JMX экспортера
└── README.md
```

## Быстрый старт

### Использование Makefile

```bash
# Собрать образ JMX Exporter
make build

# Запустить development окружение
make run

# Остановить окружение
make stop

# Остановить и удалить volumes
make clean

# Показать справку
make help
```

### Использование Docker Compose напрямую

#### Development окружение

```bash
sudo docker compose -f docker-compose.dev.yml up -d
```

#### Production окружение

```bash
sudo docker compose -f docker-compose.yml up -d
```

#### Test окружение

```bash
sudo docker compose -f docker-compose.test.yml up -d
```

## Конфигурация

### Переменные окружения

В файлах `docker-compose.dev.yml` и `docker-compose.test.yml` используются переменные окружения для настройки портов:

- `KAFKA_DOCKER_PORT` - порт для внутреннего доступа к Kafka (по умолчанию: 9092)
- `KAFKA_CLIENT_PORT` - порт для внешнего доступа к Kafka (по умолчанию: 9094)
- `KAFKA_UI_PORT` - порт для веб-интерфейса Kafka UI (по умолчанию: 8080)
- `KAFKA_JMX_PORT` - порт для JMX метрик (по умолчанию: 5556)

В `docker-compose.yml` порты заданы напрямую:
- Kafka внутренний: `9092`
- Kafka внешний: `9094`
- Kafka UI: `8080`
- JMX Exporter: `5556`

### Настройки Kafka

- **Количество партиций**: 12
- **Фактор репликации**: 1 (для development окружения)
- **JMX порт**: 9999 (внутренний)
- **Хранилище данных**: Docker volume `kafka_data`

## Сервисы

### Kafka

Apache Kafka брокер с конфигурацией для работы в режиме KRaft (без Zookeeper).

**Порты:**
- `9092` - внутренний порт для связи между сервисами
- `9094` - внешний порт для подключения клиентов

**Подключение:**
- Внутри Docker сети: `kafka:9092`
- С хоста: `localhost:9094`

### Kafka UI

Веб-интерфейс для управления и мониторинга Kafka кластера.

**Доступ:**
- URL: `http://localhost:8080` (или порт, указанный в переменной `KAFKA_UI_PORT`)

**Возможности:**
- Просмотр топиков и сообщений
- Управление топиками
- Мониторинг consumer groups
- Просмотр метрик кластера

### JMX Exporter

Экспорт метрик Kafka в формате Prometheus для мониторинга. Используется кастомный образ, собранный из `Dockerfile` на базе `bitnami/jmx-exporter:latest`.

**Порт:** `5556` (или значение `KAFKA_JMX_PORT`)

**Метрики доступны по адресу:**
- `http://localhost:5556/metrics`

**Сборка образа:**
```bash
make build
# или
sudo docker build -t kafka-jmx-exporter .
```

## Использование

### Подключение к Kafka

#### Из приложения Python

```python
from kafka import KafkaProducer, KafkaConsumer

# Producer
producer = KafkaProducer(
    bootstrap_servers=['localhost:9094']
)

# Consumer
consumer = KafkaConsumer(
    'your-topic',
    bootstrap_servers=['localhost:9094'],
    group_id='your-group-id'
)
```

#### Из приложения Java

```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9094");
props.put("group.id", "your-group-id");
KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
```

### Создание топика

Через Kafka UI или используя Kafka CLI:

```bash
docker exec -it kafka kafka-topics.sh --create \
  --topic your-topic \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1
```

## Остановка и очистка

### Остановка сервисов

```bash
make stop
# или
sudo docker compose -f docker-compose.dev.yml down
```

### Полная очистка (включая данные)

```bash
make clean
# или
sudo docker compose -f docker-compose.dev.yml down -v --remove-orphans
```

**Внимание:** Команда `clean` удалит все данные из Kafka, включая топики и сообщения.

## Мониторинг

### Метрики JMX

Метрики Kafka доступны через JMX Exporter:

```bash
curl http://localhost:5556/metrics
```

### Логи

Просмотр логов сервисов:

```bash
# Логи Kafka
docker logs kafka

# Логи Kafka UI
docker logs kafka-ui

# Логи JMX Exporter
docker logs kafka-jmx-exporter

# Логи всех сервисов
docker compose -f docker-compose.dev.yml logs -f
```

## CI/CD

Проект использует GitLab CI/CD для автоматического развертывания.

### Конфигурация

CI/CD конфигурация находится в файле `.gitlab-ci.yml` и включает следующие этапы:

- **build** - сборка Docker образа JMX Exporter
- **deploy** - автоматическое развертывание в production окружение

### Автоматическое развертывание

При коммите в ветку `master` автоматически запускается процесс сборки и деплоя в production окружение:

1. **Этап build:**
   - Собирается Docker образ `kafka_jmx_exporter` с тегом, содержащим короткий SHA коммита
   - Образ создается на сервере с тегом `prod_ms`

2. **Этап deploy:**
   - Выполняется команда `docker compose -f docker-compose.yml up -d`
   - Развертывание происходит на сервере с тегом `prod_ms`
   - Окружение помечается как `production`

