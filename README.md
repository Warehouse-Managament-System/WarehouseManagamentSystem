# 🏭 WarehouseManagamentSystem — Smart Warehouse Rental & Logistics Platform

<p align="center">
  <img src="https://img.shields.io/badge/Status-In%20Development-yellow?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/PRs-Welcome-brightgreen?style=for-the-badge" />
</p>

> A full-stack platform that connects **Warehouse Owners**, **Customers**, **Staff Workers**, and **Delivery Agents** in a seamless supply chain ecosystem — from renting storage space to delivering goods to their final destination.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [User Roles](#-user-roles)
- [Core Features](#-core-features)
- [System Flow](#-system-flow)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [API Documentation](#-api-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌐 Overview

**WarehouseHub** solves the fragmented warehouse rental and logistics market by providing a single platform where:

- Warehouse owners can **monetize their space** by publishing and renting it out.
- Customers can **rent storage**, track goods, and manage inventory in real time.
- Staff workers can **process orders** and coordinate packaging.
- Delivery agents can **accept and complete deliveries**, with automatic inventory updates on completion.

---

## 👥 User Roles

The platform supports **4 distinct roles**, chosen by the user at registration:

| Role | Description |
|------|-------------|
| 🏢 **Warehouse Owner** | Lists warehouses, defines zones/rooms, sets pricing per m² and good category |
| 🛍️ **Customer** | Rents warehouse space, manages stored goods, and places delivery orders |
| 👷 **Staff Worker** | Processes incoming orders, packages goods, and notifies delivery agents |
| 🚚 **Delivery Agent** | Accepts delivery tasks and delivers goods to specified destinations |

---

## ✨ Core Features

### 🔐 Authentication & Authorization
- Secure user **registration and login**
- **Role-based access control (RBAC)** — each role sees only its relevant dashboard and actions
- JWT-based session management

---

### 🏢 Warehouse Owner
- **Publish warehouses** with name, location, total capacity, and description
- **Divide warehouses** into named zones (e.g., "Warehouse A") and individual rooms
  - Set room dimensions (e.g., 5 rooms × 50 m²)
  - Set pricing per m² (e.g., $25/m²)
- **Categorize storage areas** by good type:
  - 🥩 Food Storage
  - 💊 Medicine / Pharmaceutical
  - ❄️ Cold Storage
  - 📦 General Goods
  - *(and more)*
- View rental occupancy, revenue, and room availability

---

### 🛍️ Customer
- **Browse and rent** available warehouses and specific rooms
- **Manage stored goods** — log what is stored, where, and how much
  - Example: *"Warehouse A → Room 3 → Bread: 200kg, Meat: 200kg"*
- **Place delivery orders** — specify goods, quantities, and destination (market, supermarket, etc.)
- View order history and real-time delivery tracking

---

### 👷 Staff Worker
- **View and accept incoming orders** from customers
- **Package goods** according to order specifications
- **Send notifications** to delivery agents when goods are ready for pickup
- Update order status throughout the packaging process

---

### 🚚 Delivery Agent
- **Receive notifications** when packages are ready
- **Accept delivery tasks** with destination details
- **Complete deliveries** to specified locations (markets, supermarkets, etc.)
- On successful delivery → warehouse inventory is **automatically updated** in real time

---

## 🔄 System Flow

```
Customer places order
        │
        ▼
Staff Worker receives order
        │
        ▼
Staff packages goods → notifies Delivery Agent
        │
        ▼
Delivery Agent accepts & delivers to destination
        │
        ▼
Warehouse inventory auto-updated ✅
```

---

## 🛠️ Tech Stack

> *(Update this section based on your actual stack)*

| Layer | Technology |
|-------|------------|
| **Frontend** | React / Next.js |
| **Backend** | Node.js / NestJS or Django |
| **Database** | PostgreSQL |
| **Auth** | JWT + Role-based middleware |
| **Real-time** | WebSockets / Firebase |
| **Containerization** | Docker + Docker Compose |
| **Cloud** | AWS / GCP / Azure |

---

## 🚀 Getting Started

### Prerequisites

- Node.js >= 18
- PostgreSQL >= 14
- Docker (optional but recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/warehousehub.git
cd warehousehub

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database credentials and JWT secret

# Run database migrations
npm run migrate

# Start the development server
npm run dev
```

The app will be available at `http://localhost:3000`

---

## 📡 API Documentation

API documentation is available at `/api/docs` (Swagger UI) once the server is running.

Key endpoint groups:

- `POST /auth/register` — Register with role selection
- `POST /auth/login` — Login and receive JWT
- `GET /warehouses` — Browse available warehouses
- `POST /warehouses` — Publish a warehouse *(Owner only)*
- `POST /orders` — Place a delivery order *(Customer only)*
- `PATCH /orders/:id/package` — Mark order as packaged *(Staff only)*
- `PATCH /orders/:id/deliver` — Complete delivery *(Delivery only)*

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for more details.

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE).

---

<p align="center">Built with ❤️ — connecting warehouses, people, and goods.</p>
