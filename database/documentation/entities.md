# User

Purpose:
Stores all users of the system.

Attributes:

- user_id
- first_name
- last_name
- email
- phone
- password_hash
- role
- city
- created_at
- account_status

# Ticket

Purpose:
Stores ticket information for sports events.

Attributes:

- ticket_id
- sport_type_id
- home_team
- away_team
- match_date
- venue_id
- price
- remaining_capacity
- category_id

# Reservation

Purpose:
Connects users to tickets.

Attributes:

- reservation_id
- user_id
- ticket_id
- status
- reservation_time
- expiration_time

# Payment

Purpose:
Stores payment transactions.

Attributes:

- payment_id
- reservation_id
- amount
- payment_method
- payment_status
- payment_time

# Report

Purpose:
Stores user complaints and issues.

Attributes:

- report_id
- user_id
- ticket_id
- category
- description
- status
- created_at

# Venue

Attributes:

- venue_id
- venue_name
- city
- address
- capacity

# SportType

Attributes:

- sport_type_id
- name

# TicketCategory

Attributes:

- category_id
- category_name

# FootballDetails

Attributes:

- football_detail_id
- ticket_id
- league_name
- stadium_section
- row_number
- seat_number
- facilities

# VolleyballDetails

Attributes:

- volleyball_detail_id
- ticket_id
- hall_name
- row_number
- seat_number
- facilities

# BasketballDetails

Attributes:

- basketball_detail_id
- ticket_id
- hall_name
- row_number
- seat_number
- facilities
