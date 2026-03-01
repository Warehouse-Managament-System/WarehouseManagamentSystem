# Warehouse Management System

A B2B SaaS platform for warehouse space rental and logistics. Warehouse owners list storage facilities with configurable zones and rooms. Business customers browse, book space, store goods, and request deliveries.

Built as a microservices architecture with 5 independently deployable Spring Boot services, event-driven communication via Apache Kafka, and database-per-service isolation.

## Architecture

| | |
|---|---|
| **Style** | Microservices (5 services) |
| **Communication** | Kafka (async events via Transactional Outbox + Debezium CDC) + REST/HTTP (sync queries via OpenFeign + Resilience4j) |
| **Auth** | Gateway-centralized JWT — validated once at API Gateway, forwarded as headers (X-User-Id, X-User-Role, X-User-Email) to downstream services |
| **Databases** | PostgreSQL (one per service) |
| **Service Discovery** | Spring Cloud Netflix Eureka |
| **Config** | Spring Cloud Config Server |
| **Gateway** | Spring Cloud Gateway |
| **Cache** | Redis 8 (booking availability locks) |
| **Payments** | Stripe (Checkout + Webhooks) |
| **Observability** | OpenTelemetry + Grafana Tempo (traces) + Grafana Loki (logs) + Grafana (dashboards) |
| **Batch** | Spring Batch 6 + Quartz |

## Services

| Service | Port | Database | Responsibilities |
|---|---|---|---|
| **Identity Service** | 8081 | identity_db | Auth, JWT token creation, users, all profile types, Super Admin ops |
| **Inventory Service** | 8082 | inventory_db | Warehouses, zones, rooms, categories, Excel import, goods items, receipts, discrepancy handling |
| **Reservation Service** | 8083 | reservation_db | Booking lifecycle, availability checks via Redis, invoices, Stripe payments, credit notes |
| **Delivery Service** | 8085 | delivery_db | Delivery requests, picking, shipments, checkpoints |
| **Platform Service** | 8087 | platform_db | Notifications, audit logs, scheduled batch jobs |

Infrastructure: API Gateway (8080), Eureka (8761), Config Server (8888), Grafana (3000), Tempo (3200), Loki (3100).

## User Roles

| Role | Description |
|---|---|
| **Super Admin** | Reviews and approves warehouse owner registrations, manages platform-level access |
| **Warehouse Owner** | Registers warehouses, configures zones/rooms via Excel import, manages staff and delivery agents, approves bookings and goods |
| **Customer** | Browses warehouses, books storage space, uploads goods lists, requests deliveries, pays invoices |
| **Staff** | Receives goods at warehouse, picks and packs orders, notifies delivery agents |
| **Delivery Agent** | Claims deliveries (first-come-first-served), picks up goods, updates shipment checkpoints |

## Documentation

Full architecture documentation is hosted as an HTML site via **GitHub Pages**:

**https://Warehouse-Managament-System.github.io/WarehouseManagamentSystem/**

| Page | Description |
|---|---|
| [Overview](docs/index.html) | Architecture overview, services, tech stack |
| [C4 Architecture](docs/c4.html) | Interactive C4 model — L1 Context, L2 Container, L3 Component, L4 Code |
| [Database](docs/database.html) | Design decisions, 36 tables across 5 databases, entity schemas |
| [API](docs/api.html) | All ~60 REST endpoints grouped by service and role |
| [Kafka Events](docs/kafka.html) | Event types, payload contracts, consumer groups, DLT |
| [Database Schema (SQL)](docs/database-schema.sql) | Full PostgreSQL DDL with all constraints and indexes |

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Java 25 |
| Framework | Spring Boot 4, Spring Cloud 2025.x |
| Build | Gradle (Kotlin DSL) |
| Database | PostgreSQL 18, Spring Data JPA, Flyway |
| Messaging | Apache Kafka 4, Spring Kafka, Debezium CDC |
| Cache | Redis 8, Spring Data Redis |
| Security | Spring Security 7, JWT (jjwt) — validated at API Gateway |
| Payments | Stripe Java SDK |
| Excel | Apache POI |
| Resilience | Resilience4j (circuit breaker, retry, time limiter) |
| Service Comm | OpenFeign, Spring Cloud LoadBalancer |
| Observability | OpenTelemetry, Grafana Tempo, Grafana Loki, Grafana |
| Batch | Spring Batch 6, Quartz |
| Containers | Docker, Docker Compose |

## Getting Started

### Prerequisites

- Java 25+
- Docker and Docker Compose
- Gradle 9+ (or use the included wrapper)

### Run

```bash
# Start all infrastructure (databases, Kafka, Redis, Eureka, etc.)
docker-compose up -d

# Run a specific service
./gradlew :identity-service:bootRun
```

### Project Structure

```
wms-platform/
├── wms-common/                  # Shared library (DTOs, exceptions, outbox, security utils)
├── identity-service/            # Auth + Users + Profiles
├── inventory-service/           # Warehouses + Zones + Rooms + Goods + Receipts
├── reservation-service/         # Bookings + Availability + Invoices + Payments
├── delivery-service/            # Deliveries + Shipments + Checkpoints
├── platform-service/            # Notifications + Audit + Scheduler
├── api-gateway/                 # Spring Cloud Gateway + JWT validation
├── config-server/               # Spring Cloud Config Server
├── eureka-server/               # Service Discovery
├── docs/                        # Architecture documentation (GitHub Pages)
│   ├── index.html               # Overview — services, roles, tech stack
│   ├── c4.html                  # Interactive C4 model (L1–L4)
│   ├── database.html            # Database design, tables across 5 DBs
│   ├── api.html                 # ~60 REST endpoints by service and role
│   ├── kafka.html               # Kafka events, DLT, consumer groups
│   ├── database-schema.sql      # Full PostgreSQL DDL
│   └── style.css                # Shared site styling
└── docker-compose.yml
```

## License

MIT
