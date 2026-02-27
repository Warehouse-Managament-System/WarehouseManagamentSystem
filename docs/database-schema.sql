-- ============================================================
-- Warehouse Management System — PostgreSQL Schema
-- ============================================================

-- ============================================================
-- AUTH & USERS
-- ============================================================

CREATE TABLE users (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    email      VARCHAR(255) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name  VARCHAR(100) NOT NULL,
    phone      VARCHAR(20)  NOT NULL,
    role       VARCHAR(20)  NOT NULL CHECK (role IN ('SUPER_ADMIN','WAREHOUSE_OWNER','STAFF','DELIVERY_AGENT','CUSTOMER')),
    status     VARCHAR(20)  NOT NULL CHECK (status IN ('ACTIVE','SUSPENDED','PENDING')),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- WAREHOUSE (must be created before profile tables that reference it)
-- ============================================================

CREATE TABLE warehouses (
    id                 UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id           UUID          NOT NULL REFERENCES users(id),
    name               VARCHAR(255)  NOT NULL,
    description        TEXT          NOT NULL,
    address            VARCHAR(255)  NOT NULL,
    city               VARCHAR(100)  NOT NULL,
    country            VARCHAR(100)  NOT NULL,
    latitude           DECIMAL(9,6)  NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude          DECIMAL(9,6)  NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    total_surface_area DECIMAL(10,2) NOT NULL CHECK (total_surface_area > 0),
    status             VARCHAR(20)   NOT NULL CHECK (status IN ('DRAFT','PUBLISHED','SUSPENDED','INACTIVE')),
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE warehouse_images (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID         NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    url          VARCHAR(500) NOT NULL,
    is_primary   BOOLEAN      NOT NULL DEFAULT false,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_warehouse_images_one_primary
    ON warehouse_images (warehouse_id)
    WHERE is_primary = true;

CREATE TABLE warehouse_excel_imports (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id   UUID         NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    owner_id       UUID         NOT NULL REFERENCES users(id),
    file_name      VARCHAR(255) NOT NULL,
    status         VARCHAR(20)  NOT NULL CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
    total_rows     INT          NOT NULL DEFAULT 0 CHECK (total_rows >= 0),
    success_rows   INT          NOT NULL DEFAULT 0 CHECK (success_rows >= 0),
    failed_rows    INT          NOT NULL DEFAULT 0 CHECK (failed_rows >= 0),
    error_file_url VARCHAR(500) NOT NULL DEFAULT '',
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- USER PROFILES (after warehouses, since staff/agent reference it)
-- ============================================================

CREATE TABLE warehouse_owner_profiles (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name     VARCHAR(255) NOT NULL,
    tax_id           VARCHAR(100) NOT NULL UNIQUE,
    address          VARCHAR(255) NOT NULL,
    city             VARCHAR(100) NOT NULL,
    country          VARCHAR(100) NOT NULL,
    approved_by      UUID         REFERENCES users(id),
    approved_at      TIMESTAMPTZ,
    rejection_reason VARCHAR(500),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at       TIMESTAMPTZ
);

CREATE TABLE customer_profiles (
    id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    company_name        VARCHAR(255) NOT NULL,
    tax_id              VARCHAR(100) NOT NULL UNIQUE,
    address             VARCHAR(255) NOT NULL,
    city                VARCHAR(100) NOT NULL,
    country             VARCHAR(100) NOT NULL,
    contact_person_name VARCHAR(255) NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE staff_profiles (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    warehouse_id UUID         NOT NULL REFERENCES warehouses(id),
    position     VARCHAR(100) NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE delivery_agent_profiles (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    warehouse_id UUID         NOT NULL REFERENCES warehouses(id),
    vehicle_info VARCHAR(255) NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- CATEGORIES (standalone, linked to zones/rooms via junction tables)
-- ============================================================

CREATE TABLE categories (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- ZONES & ROOMS
-- ============================================================

CREATE TABLE zones (
    id                 UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id       UUID          NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
    name               VARCHAR(100)  NOT NULL,
    description        VARCHAR(255)  NOT NULL,
    temperature_type   VARCHAR(20)   NOT NULL CHECK (temperature_type IN ('AMBIENT','REFRIGERATED','FROZEN')),
    total_surface_area DECIMAL(10,2) NOT NULL CHECK (total_surface_area > 0),
    status             VARCHAR(20)   NOT NULL CHECK (status IN ('ACTIVE','MAINTENANCE','INACTIVE')),
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    UNIQUE (warehouse_id, name)
);

CREATE TABLE zone_categories (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id     UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    category_id UUID        NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (zone_id, category_id)
);

CREATE TABLE zone_availabilities (
    id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id    UUID        NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    start_date DATE        NOT NULL,
    end_date   DATE        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_zone_availability_dates CHECK (end_date > start_date)
);

CREATE TABLE rooms (
    id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id               UUID          NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    name                  VARCHAR(100)  NOT NULL,
    description           VARCHAR(255)  NOT NULL,
    total_surface_area    DECIMAL(10,2) NOT NULL CHECK (total_surface_area > 0),
    price_per_sqm_daily   DECIMAL(10,2) NOT NULL CHECK (price_per_sqm_daily > 0),
    price_per_sqm_weekly  DECIMAL(10,2) NOT NULL CHECK (price_per_sqm_weekly > 0),
    price_per_sqm_monthly DECIMAL(10,2) NOT NULL CHECK (price_per_sqm_monthly > 0),
    status                VARCHAR(20)   NOT NULL CHECK (status IN ('AVAILABLE','BOOKED','MAINTENANCE')),
    created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at            TIMESTAMPTZ,
    UNIQUE (zone_id, name)
);

CREATE TABLE room_categories (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id     UUID        NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    category_id UUID        NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (room_id, category_id)
);

-- ============================================================
-- BOOKING
-- ============================================================

CREATE TABLE bookings (
    id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id  UUID          NOT NULL REFERENCES users(id),
    warehouse_id UUID          NOT NULL REFERENCES warehouses(id),
    booking_type VARCHAR(20)   NOT NULL CHECK (booking_type IN ('ROOM','ZONE','WAREHOUSE')),
    room_id      UUID          REFERENCES rooms(id),
    zone_id      UUID          REFERENCES zones(id),
    start_date   DATE          NOT NULL,
    end_date     DATE          NOT NULL,
    surface_area DECIMAL(10,2) NOT NULL CHECK (surface_area > 0),
    total_price  DECIMAL(10,2) NOT NULL CHECK (total_price >= 0),
    status       VARCHAR(20)   NOT NULL CHECK (status IN ('PENDING','CONFIRMED','ACTIVE','EXPIRED','CANCELLED')),
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at   TIMESTAMPTZ,
    CONSTRAINT chk_booking_dates CHECK (end_date > start_date),
    CONSTRAINT chk_booking_type_refs CHECK (
        (booking_type = 'ROOM'      AND room_id IS NOT NULL AND zone_id IS NULL) OR
        (booking_type = 'ZONE'      AND zone_id IS NOT NULL AND room_id IS NULL) OR
        (booking_type = 'WAREHOUSE' AND room_id IS NULL     AND zone_id IS NULL)
    )
);

CREATE TABLE booking_expiry_notifications (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID        NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    notified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status      VARCHAR(20) NOT NULL CHECK (status IN ('SENT','ACKNOWLEDGED')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- GOODS
-- ============================================================

CREATE TABLE goods_excel_imports (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id       UUID         NOT NULL REFERENCES bookings(id),
    customer_id      UUID         NOT NULL REFERENCES users(id),
    file_name        VARCHAR(255) NOT NULL,
    status           VARCHAR(20)  NOT NULL CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    total_rows       INT          NOT NULL DEFAULT 0 CHECK (total_rows >= 0),
    success_rows     INT          NOT NULL DEFAULT 0 CHECK (success_rows >= 0),
    failed_rows      INT          NOT NULL DEFAULT 0 CHECK (failed_rows >= 0),
    error_file_url   VARCHAR(500) NOT NULL DEFAULT '',
    arrival_deadline TIMESTAMPTZ  NOT NULL,
    approved_by      UUID         REFERENCES users(id),
    approved_at      TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE goods_items (
    id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    goods_import_id UUID          NOT NULL REFERENCES goods_excel_imports(id) ON DELETE CASCADE,
    name            VARCHAR(255)  NOT NULL,
    sku             VARCHAR(100)  NOT NULL,
    barcode         VARCHAR(100)  NOT NULL,
    quantity        DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
    status          VARCHAR(20)   NOT NULL CHECK (status IN ('PENDING','IN_WAREHOUSE','DELIVERED','DAMAGED')),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ,
    UNIQUE (goods_import_id, sku),
    UNIQUE (goods_import_id, barcode)
);

-- ============================================================
-- GOODS RECEIPTS
-- ============================================================

CREATE TABLE goods_receipts (
    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID         NOT NULL REFERENCES bookings(id),
    received_by     UUID         NOT NULL REFERENCES users(id),
    inbound_carrier VARCHAR(255) NOT NULL,
    received_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    notes           TEXT         NOT NULL DEFAULT ''
);

CREATE TABLE goods_receipt_items (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    goods_receipt_id UUID          NOT NULL REFERENCES goods_receipts(id) ON DELETE CASCADE,
    goods_item_id    UUID          NOT NULL REFERENCES goods_items(id),
    expected_qty     DECIMAL(10,2) NOT NULL CHECK (expected_qty > 0),
    received_qty     DECIMAL(10,2) NOT NULL CHECK (received_qty >= 0),
    condition        VARCHAR(10)   NOT NULL CHECK (condition IN ('GOOD','DAMAGED','REJECTED')),
    notes            TEXT          NOT NULL DEFAULT '',
    UNIQUE (goods_receipt_id, goods_item_id)
);

-- ============================================================
-- DELIVERY
-- ============================================================

CREATE TABLE delivery_requests (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id          UUID        NOT NULL REFERENCES bookings(id),
    customer_id         UUID        NOT NULL REFERENCES users(id),
    destination_address VARCHAR(255) NOT NULL,
    destination_city    VARCHAR(100) NOT NULL,
    destination_country VARCHAR(100) NOT NULL,
    requested_date      DATE        NOT NULL,
    status              VARCHAR(20) NOT NULL CHECK (status IN ('PENDING','CONFIRMED','PICKING','DISPATCHED','DELIVERED','CANCELLED')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE delivery_request_items (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id UUID          NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    goods_item_id       UUID          NOT NULL REFERENCES goods_items(id),
    requested_qty       DECIMAL(10,2) NOT NULL CHECK (requested_qty > 0),
    picked_qty          DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (picked_qty >= 0),
    picked_by           UUID          REFERENCES users(id),
    picked_at           TIMESTAMPTZ,
    UNIQUE (delivery_request_id, goods_item_id)
);

CREATE TABLE delivery_notifications (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id UUID        NOT NULL REFERENCES delivery_requests(id) ON DELETE CASCADE,
    notified_by         UUID        NOT NULL REFERENCES users(id),
    notified_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    status              VARCHAR(20) NOT NULL CHECK (status IN ('OPEN','CLAIMED','EXPIRED')),
    expires_at          TIMESTAMPTZ NOT NULL
);

CREATE TABLE shipments (
    id                      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_request_id     UUID         NOT NULL REFERENCES delivery_requests(id),
    claimed_by              UUID         NOT NULL REFERENCES users(id),
    claimed_at              TIMESTAMPTZ  NOT NULL,
    scheduled_pickup_time   TIMESTAMPTZ  NOT NULL,
    tracking_number         VARCHAR(100) NOT NULL UNIQUE,
    estimated_delivery_date DATE         NOT NULL,
    actual_delivery_date    DATE,
    status                  VARCHAR(20)  NOT NULL CHECK (status IN ('PENDING','PICKED_UP','IN_TRANSIT','DELIVERED')),
    notes                   TEXT         NOT NULL DEFAULT '',
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE shipment_checkpoints (
    id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_id UUID         NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    status      VARCHAR(20)  NOT NULL CHECK (status IN ('PENDING','PICKED_UP','IN_TRANSIT','DELIVERED')),
    location    VARCHAR(255) NOT NULL,
    note        TEXT         NOT NULL DEFAULT '',
    recorded_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- BILLING
-- ============================================================

CREATE TABLE invoices (
    id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID          NOT NULL REFERENCES users(id),
    warehouse_id        UUID          NOT NULL REFERENCES warehouses(id),
    booking_id          UUID          REFERENCES bookings(id),
    delivery_request_id UUID          REFERENCES delivery_requests(id),
    invoice_type        VARCHAR(20)   NOT NULL CHECK (invoice_type IN ('BOOKING','DELIVERY')),
    amount              DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    currency            VARCHAR(3)    NOT NULL DEFAULT 'USD',
    status              VARCHAR(20)   NOT NULL CHECK (status IN ('DRAFT','SENT','PAID','OVERDUE','CANCELLED')),
    due_date            DATE          NOT NULL,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_invoice_type_refs CHECK (
        (invoice_type = 'BOOKING'  AND booking_id IS NOT NULL AND delivery_request_id IS NULL) OR
        (invoice_type = 'DELIVERY' AND delivery_request_id IS NOT NULL AND booking_id IS NULL)
    )
);

CREATE TABLE invoice_items (
    id          UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID          NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description VARCHAR(255)  NOT NULL,
    quantity    DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    total       DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE payments (
    id                 UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id         UUID          NOT NULL REFERENCES invoices(id),
    stripe_payment_id  VARCHAR(255)  NOT NULL UNIQUE,
    stripe_receipt_url VARCHAR(500)  NOT NULL,
    amount             DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status             VARCHAR(20)   NOT NULL CHECK (status IN ('PENDING','SUCCESS','FAILED')),
    failure_reason     VARCHAR(255)  NOT NULL DEFAULT '',
    paid_at            TIMESTAMPTZ,
    created_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE credit_notes (
    id         UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID          NOT NULL REFERENCES invoices(id),
    reason     TEXT          NOT NULL,
    amount     DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    created_at TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE notifications (
    id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type       VARCHAR(50)  NOT NULL CHECK (type IN (
                   'WAREHOUSE_APPROVED',
                   'WAREHOUSE_REJECTED',
                   'BOOKING_CONFIRMED',
                   'BOOKING_CANCELLED',
                   'BOOKING_EXPIRY',
                   'GOODS_APPROVED',
                   'GOODS_REJECTED',
                   'GOODS_DISCREPANCY',
                   'DELIVERY_AVAILABLE',
                   'DELIVERY_CLAIMED',
                   'DELIVERY_PICKUP_REMINDER',
                   'DELIVERY_UPDATE',
                   'INVOICE_GENERATED',
                   'PAYMENT_SUCCESS',
                   'PAYMENT_FAILED')),
    message    TEXT         NOT NULL,
    is_read    BOOLEAN      NOT NULL DEFAULT false,
    read_at    TIMESTAMPTZ,
    link       VARCHAR(500) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- AUDIT
-- ============================================================

CREATE TABLE audit_logs (
    id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    performed_by UUID         NOT NULL,
    action       VARCHAR(100) NOT NULL,
    entity_type  VARCHAR(100) NOT NULL,
    entity_id    UUID         NOT NULL,
    old_value    JSONB,
    new_value    JSONB,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ============================================================
-- OUTBOX (Transactional Outbox Pattern — one per service DB)
-- Each service writes events to this table in the SAME
-- transaction as its business data. A poller reads pending
-- events and publishes them to Kafka, guaranteeing
-- at-least-once delivery with no data inconsistency.
-- ============================================================

CREATE TABLE outbox_events (
    id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id   UUID         NOT NULL,
    event_type     VARCHAR(100) NOT NULL,
    payload        JSONB        NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SENT','FAILED')),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    published_at   TIMESTAMPTZ
);

CREATE INDEX idx_outbox_pending ON outbox_events(status) WHERE status = 'PENDING';

-- ============================================================
-- INDEXES (PostgreSQL does NOT auto-create indexes on FK columns)
-- ============================================================

CREATE INDEX idx_warehouses_owner_id ON warehouses(owner_id);
CREATE INDEX idx_zones_warehouse_id ON zones(warehouse_id);
CREATE INDEX idx_rooms_zone_id ON rooms(zone_id);
CREATE INDEX idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX idx_bookings_warehouse_id ON bookings(warehouse_id);
CREATE INDEX idx_bookings_room_id ON bookings(room_id);
CREATE INDEX idx_bookings_zone_id ON bookings(zone_id);
CREATE INDEX idx_goods_items_import_id ON goods_items(goods_import_id);
CREATE INDEX idx_goods_receipts_booking_id ON goods_receipts(booking_id);
CREATE INDEX idx_delivery_requests_booking_id ON delivery_requests(booking_id);
CREATE INDEX idx_delivery_requests_customer_id ON delivery_requests(customer_id);
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX idx_invoices_warehouse_id ON invoices(warehouse_id);
CREATE INDEX idx_invoices_booking_id ON invoices(booking_id);
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_performed_by ON audit_logs(performed_by);
