-- =============================================================================
-- Database Project: PL/pgSQL Stored Procedures & Functions
-- File: procedures.sql
-- Database Engine: PostgreSQL
-- =============================================================================

-- 1. Get user's purchased tickets by phone number or email
CREATE OR REPLACE FUNCTION get_user_paid_tickets(p_contact VARCHAR)
RETURNS TABLE(ticket_id INT, title TEXT, match_date TIMESTAMP, price NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT t.ticket_id, (t.home_team || ' vs ' || t.away_team) AS title, t.match_date, t.price
    FROM tickets t
    JOIN reservations r ON t.ticket_id = r.ticket_id
    JOIN users u ON r.user_id = u.user_id
    WHERE (u.phone_number = p_contact OR u.email = p_contact) AND r.status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- 2. Get list of cancelled reservations handled by a SPECIFIC SUPPORT STAFF
CREATE OR REPLACE FUNCTION get_cancelled_reservations_by_support(p_support_contact VARCHAR)
RETURNS TABLE(reservation_id INT, ticket_title TEXT, user_name TEXT, reserved_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.reservation_id, 
        (t.home_team || ' vs ' || t.away_team) AS ticket_title, 
        (u.first_name || ' ' || u.last_name) AS user_name,
        r.reserved_at
    FROM reservations r
    JOIN users u ON r.user_id = u.user_id 
    JOIN tickets t ON r.ticket_id = t.ticket_id
    JOIN users s ON r.cancelled_by_support_id = s.user_id
    WHERE (s.phone_number = p_support_contact OR s.email = p_support_contact) 
      AND r.status = 'cancelled';
END;
$$ LANGUAGE plpgsql;

-- 3. Get tickets purchased in a given city
CREATE OR REPLACE FUNCTION get_tickets_by_city(p_city VARCHAR)
RETURNS TABLE(ticket_id INT, title TEXT, venue_name VARCHAR, match_date TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT t.ticket_id, (t.home_team || ' vs ' || t.away_team) AS title, t.venue_name, t.match_date
    FROM tickets t
    JOIN reservations r ON t.ticket_id = r.ticket_id
    WHERE t.city = p_city AND r.status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- 4. Search tickets by keyword in spectator name, teams/leagues, venue, or title
CREATE OR REPLACE FUNCTION search_tickets_by_keyword(p_keyword VARCHAR)
RETURNS TABLE(ticket_id INT, ticket_title TEXT, spectator_name TEXT, venue_name VARCHAR, match_date TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.ticket_id,
        (t.home_team || ' vs ' || t.away_team) AS ticket_title,
        (u.first_name || ' ' || u.last_name) AS spectator_name,
        t.venue_name,
        t.match_date
    FROM tickets t
    LEFT JOIN reservations r ON t.ticket_id = r.ticket_id
    LEFT JOIN users u ON r.user_id = u.user_id
    LEFT JOIN football_details fd ON t.ticket_id = fd.ticket_id
    LEFT JOIN volleyball_details vd ON t.ticket_id = vd.ticket_id
    LEFT JOIN basketball_details bd ON t.ticket_id = bd.ticket_id
    WHERE t.venue_name ILIKE '%' || p_keyword || '%' 
       OR t.home_team ILIKE '%' || p_keyword || '%'
       OR t.away_team ILIKE '%' || p_keyword || '%'
       OR u.first_name ILIKE '%' || p_keyword || '%'
       OR u.last_name ILIKE '%' || p_keyword || '%'
       OR fd.league_name ILIKE '%' || p_keyword || '%'
       OR vd.league_name ILIKE '%' || p_keyword || '%'
       OR bd.league_name ILIKE '%' || p_keyword || '%';
END;
$$ LANGUAGE plpgsql;

-- 5. Get purchases made by fellow citizens of a given user (by contact)
CREATE OR REPLACE FUNCTION get_co_citizens_purchases(p_contact VARCHAR)
RETURNS TABLE(co_citizen_name TEXT, ticket_title TEXT) AS $$
DECLARE
    v_user_city VARCHAR;
BEGIN
    SELECT city INTO v_user_city FROM users WHERE phone_number = p_contact OR email = p_contact LIMIT 1;
    
    RETURN QUERY
    SELECT (u.first_name || ' ' || u.last_name) AS co_citizen_name, (t.home_team || ' vs ' || t.away_team) AS ticket_title
    FROM users u
    JOIN reservations r ON u.user_id = r.user_id
    JOIN tickets t ON r.ticket_id = t.ticket_id
    WHERE u.city = v_user_city AND r.status = 'paid'
      AND u.phone_number != p_contact AND u.email != p_contact; -- (جلوگیری از نمایش خود فرد)
END;
$$ LANGUAGE plpgsql;

-- 6. Get top N buyers who purchased tickets after a specific date
CREATE OR REPLACE FUNCTION get_top_buyers_after_date(p_date TIMESTAMP, p_limit INT)
RETURNS TABLE(full_name TEXT, purchase_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT (u.first_name || ' ' || u.last_name) AS full_name, COUNT(r.reservation_id) AS p_count
    FROM users u
    JOIN reservations r ON u.user_id = r.user_id
    WHERE r.status = 'paid' AND r.reserved_at >= p_date
    GROUP BY u.user_id, u.first_name, u.last_name
    ORDER BY p_count DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 7. Get cancelled tickets filtered by sport type ordered by date
CREATE OR REPLACE FUNCTION get_cancelled_tickets_by_sport(p_sport_type sport_type_enum)
RETURNS TABLE(reservation_id INT, ticket_title TEXT, reserved_at TIMESTAMP) AS $$
BEGIN
    RETURN QUERY
    SELECT r.reservation_id, (t.home_team || ' vs ' || t.away_team) AS ticket_title, r.reserved_at
    FROM reservations r
    JOIN tickets t ON r.ticket_id = t.ticket_id
    WHERE t.sport_type = p_sport_type AND r.status = 'cancelled'
    ORDER BY r.reserved_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 8. Get users with the highest number of reports in a specific category
CREATE OR REPLACE FUNCTION get_users_with_most_reports_by_category(p_category VARCHAR)
RETURNS TABLE(full_name TEXT, report_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT (u.first_name || ' ' || u.last_name) AS full_name, COUNT(rep.report_id) AS r_count
    FROM users u
    JOIN reports rep ON u.user_id = rep.user_id
    WHERE rep.category = p_category
    GROUP BY u.user_id, u.first_name, u.last_name
    ORDER BY r_count DESC;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TEST EXECUTION COMMANDS (FOR TA AND EVALUATOR)
-- =============================================================================
/*
SELECT * FROM get_user_paid_tickets('ali@example.com');
SELECT * FROM get_cancelled_reservations_by_support('admin@example.com');
SELECT * FROM get_tickets_by_city('Tehran');
SELECT * FROM search_tickets_by_keyword('خلیج فارس');
SELECT * FROM search_tickets_by_keyword('مریم کاظمی');
SELECT * FROM get_co_citizens_purchases('09121111111');
SELECT * FROM get_top_buyers_after_date(CURRENT_TIMESTAMP - INTERVAL '30 days', 3);
SELECT * FROM get_cancelled_tickets_by_sport('football');
SELECT * FROM get_users_with_most_reports_by_category('مشکل لغو رزرو (Cancellation Issue)');
*/