# 📊 Phase 1 Technical Report: Database Architecture & ERD Design

**Project Title:** Sports Ticket Booking & Reservation Platform  
**Selected Database Engine:** PostgreSQL

---

## 1. Overview & Architecture Goals

The primary objective of Phase 1 is to design a normalized, robust, and highly scalable relational database structure (3NF) tailored for a sports ticket booking system. The architecture eliminates data redundancy, enforces domain integrity, and optimizes execution speed for search-heavy workloads.

## 2. Core Entities & Key Relationships

1. **`users`**: Stores user authentication profiles, soft-delete statuses, and role-based access (`audience` vs. `support`).
2. **`tickets`**: Base entity holding common match metadata (sport type, organizer, date, capacity, and price).
3. **`football_details`, `volleyball_details`, `basketball_details`**: 1-to-1 extension tables storing sport-specific attributes (VIP access, indoor/outdoor features, stand sections) without polluting the base ticket table with NULL columns.
4. **`reservations`**: Manages temporary (10-minute hold) and permanent ticket reservations (1-to-N from Users and Tickets).
5. **`payments`**: Captures transaction history linked 1-to-1 with reservations.
6. **`reports`**: Allows users to log issues or complaints directly for support staff review.

## 3. Third Normal Form (3NF) Justification

All tables conform to 3NF standards:

- **No Partial Dependencies:** Every non-key attribute fully depends on the primary key.
- **No Transitive Dependencies:** Attributes specific to sports (e.g., stadium roof type or court-side seating) were decomposed into distinct specialized tables, preventing redundant NULL fields in general ticket records.

## 4. Integrity Constraints & Business Logic

- **Check Constraints:** Enforces non-negative ticket pricing (`price >= 0`) and available seats (`remaining_capacity >= 0`).
- **Date Checks:** Ensures expiration timestamps strictly succeed reservation creation (`reserved_at < expires_at`).
- **Uniqueness:** Guarantees unique user phone numbers and email addresses.

## 5. Indexing Strategy for High Performance

To fulfill the platform's core requirement of fast searching and filtering, B-Tree indexes were created:

- `idx_tickets_sport_city`: Optimizes filtered queries on sport type and location.
- `idx_tickets_match_date`: Accelerates chronological sorting for upcoming matches.
- `idx_reservations_user_status`: Improves lookup speeds for active user reservations.
