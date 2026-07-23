-- =============================================================================
-- Database Project: PL/pgSQL Stored Procedures & Functions
-- File: database/scripts/procedures.sql
-- Database Engine: PostgreSQL
-- =============================================================================

-- 1. Get user's purchased tickets by phone number or email
CREATE OR REPLACE FUNCTION get_user_paid_tickets(p_contact VARCHAR)
RETURNS TABLE(ticket_id INT, title VARCHAR, match_date TIMESTAMP, price NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT t.ticket_id, t.title, t.match_date, t.price
    FROM tickets t
    JOIN reservations r ON t.ticket_id = r.ticket_id
    JOIN users u ON r.user_id = u.user_id
    WHERE (u.phone_number = p_contact OR u.email = p_contact) AND r.status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- 2. Get list of cancelled reservations for a specific user by phone number or email
CREATE OR REPLACE FUNCTION get_cancelled_reservations_by_user(p_contact VARCHAR)
RETURNS TABLE(reservation_id INT, ticket_title VARCHAR, reserved_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.reservation_id, 
        t.title AS ticket_title, 
        r.reserved_at
    FROM reservations r
    JOIN users u ON r.user_id = u.user_id
    JOIN tickets t ON r.ticket_id = t.ticket_id
    WHERE (u.phone_number = p_contact OR u.email = p_contact) 
      AND r.status = 'cancelled';
END;
$$ LANGUAGE plpgsql;

-- 3. Get tickets purchased in a given city
CREATE OR REPLACE FUNCTION get_tickets_by_city(p_city VARCHAR)
RETURNS TABLE(ticket_id INT, title VARCHAR, venue_name VARCHAR, match_date TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT t.ticket_id, t.title, t.venue_name, t.match_date
    FROM tickets t
    JOIN reservations r ON t.ticket_id = r.ticket_id
    WHERE t.city = p_city AND r.status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- 4. Search tickets by venue name or title keyword
CREATE OR REPLACE FUNCTION search_tickets_by_keyword(p_keyword VARCHAR)
RETURNS TABLE(ticket_id INT, title VARCHAR, venue_name VARCHAR, price NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT t.ticket_id, t.title, t.venue_name, t.price
    FROM tickets t
    WHERE t.venue_name ILIKE '%' || p_keyword || '%' OR t.title ILIKE '%' || p_keyword || '%';
END;
$$ LANGUAGE plpgsql;

-- 5. Get purchases made by fellow citizens of a given user (by contact)
CREATE OR REPLACE FUNCTION get_co_citizens_purchases(p_contact VARCHAR)
RETURNS TABLE(co_citizen_name VARCHAR, ticket_title VARCHAR) AS $$
DECLARE
    v_user_city VARCHAR;
BEGIN
    SELECT city INTO v_user_city FROM users WHERE phone_number = p_contact OR email = p_contact;
    
    RETURN QUERY
    SELECT u.full_name, t.title
    FROM users u
    JOIN reservations r ON u.user_id = r.user_id
    JOIN tickets t ON r.ticket_id = t.ticket_id
    WHERE u.city = v_user_city AND r.status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- 6. Get top N buyers who purchased tickets after a specific date
CREATE OR REPLACE FUNCTION get_top_buyers_after_date(p_date TIMESTAMP, p_limit INT)
RETURNS TABLE(full_name VARCHAR, purchase_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT u.full_name, COUNT(r.reservation_id) AS p_count
    FROM users u
    JOIN reservations r ON u.user_id = r.user_id
    WHERE r.status = 'paid' AND r.reserved_at >= p_date
    GROUP BY u.user_id, u.full_name
    ORDER BY p_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 7. Get cancelled tickets filtered by sport type ordered by date
CREATE OR REPLACE FUNCTION get_cancelled_tickets_by_sport(p_sport_type sport_type_enum)
RETURNS TABLE(reservation_id INT, ticket_title VARCHAR, reserved_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT r.reservation_id, t.title, r.reserved_at
    FROM reservations r
    JOIN tickets t ON r.ticket_id = t.ticket_id
    WHERE t.sport_type = p_sport_type AND r.status = 'cancelled'
    ORDER BY r.reserved_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 8. Get users with the highest number of reports in a specific category
CREATE OR REPLACE FUNCTION get_users_with_most_reports_by_category(p_category VARCHAR)
RETURNS TABLE(full_name VARCHAR, report_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT u.full_name, COUNT(rep.report_id) AS r_count
    FROM users u
    JOIN reports rep ON u.user_id = rep.user_id
    WHERE rep.category = p_category
    GROUP BY u.user_id, u.full_name
    ORDER BY r_count DESC;
END;
$$ LANGUAGE plpgsql;