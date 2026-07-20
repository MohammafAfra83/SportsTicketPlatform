-- =============================================================================
-- Database Project: Analytical Queries & PL/pgSQL Stored Procedures
-- File: database/queries_and_procedures.sql
-- Database Engine: PostgreSQL
-- =============================================================================

-- =============================================================================
-- PART 1: 23 Analytical SQL Queries
-- =============================================================================

-- 1. Full name of users who have never reserved any ticket
SELECT full_name 
FROM users 
WHERE user_id NOT IN (SELECT DISTINCT user_id FROM reservations);

-- 2. Full name of users who have purchased at least one ticket (successful payment)
SELECT DISTINCT u.full_name 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
JOIN payments p ON r.reservation_id = p.reservation_id 
WHERE p.status = 'successful';

-- 3. Total amount paid by each user in the last month
SELECT user_id, SUM(amount) AS total_paid 
FROM payments 
WHERE status = 'successful' AND paid_at >= CURRENT_TIMESTAMP - INTERVAL '1 month' 
GROUP BY user_id;

-- 4. Users who purchased a ticket exactly once in each city
SELECT u.user_id, u.full_name, t.city 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
JOIN tickets t ON r.ticket_id = t.ticket_id 
JOIN payments p ON r.reservation_id = p.reservation_id 
WHERE p.status = 'successful' 
GROUP BY u.user_id, u.full_name, t.city 
HAVING COUNT(r.reservation_id) = 1;

-- 5. Information of user(s) who made the most recent ticket purchase
SELECT u.* FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
JOIN payments p ON r.reservation_id = p.reservation_id 
WHERE p.status = 'successful' 
ORDER BY p.paid_at DESC 
LIMIT 1;

-- 6. Phone number and email of users whose total spending exceeds average spending of all users
SELECT u.phone_number, u.email 
FROM users u 
JOIN payments p ON u.user_id = p.user_id 
WHERE p.status = 'successful' 
GROUP BY u.user_id, u.phone_number, u.email 
HAVING SUM(p.amount) > (SELECT AVG(amount) FROM payments WHERE status = 'successful');

-- 7. Total count of tickets sold categorized by sport type
SELECT t.sport_type, COUNT(r.reservation_id) AS total_sold 
FROM tickets t 
JOIN reservations r ON t.ticket_id = r.ticket_id 
WHERE r.status = 'paid' 
GROUP BY t.sport_type;

-- 8. Top 3 buyers with the highest number of ticket purchases in the last week
SELECT u.full_name, COUNT(r.reservation_id) AS ticket_count 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
WHERE r.status = 'paid' AND r.reserved_at >= CURRENT_TIMESTAMP - INTERVAL '1 week' 
GROUP BY u.user_id, u.full_name 
ORDER BY ticket_count DESC 
LIMIT 3;

-- 9. Number of tickets sold in Tehran province categorized by city
SELECT t.city, COUNT(r.reservation_id) AS sold_count 
FROM tickets t 
JOIN reservations r ON t.ticket_id = r.ticket_id 
WHERE t.city = 'Tehran' AND r.status = 'paid' 
GROUP BY t.city;

-- 10. Distinct cities where the oldest registered user in the system bought tickets
SELECT DISTINCT t.city 
FROM tickets t 
JOIN reservations r ON t.ticket_id = r.ticket_id 
WHERE r.user_id = (SELECT user_id FROM users ORDER BY created_at ASC LIMIT 1);

-- 11. Names of support team members who manage the platform
SELECT full_name 
FROM users 
WHERE role = 'support';

-- 12. Names of users who purchased at least 2 tickets
SELECT u.full_name 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
WHERE r.status = 'paid' 
GROUP BY u.user_id, u.full_name 
HAVING COUNT(r.reservation_id) >= 2;

-- 13. Names of users who bought at most 2 tickets for a specific sport (e.g., Football)
SELECT u.full_name 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
JOIN tickets t ON r.ticket_id = t.ticket_id 
WHERE t.sport_type = 'football' AND r.status = 'paid' 
GROUP BY u.user_id, u.full_name 
HAVING COUNT(r.reservation_id) <= 2;

-- 14. Contact info of users who bought tickets across all available sport types
SELECT u.phone_number, u.email 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
JOIN tickets t ON r.ticket_id = t.ticket_id 
WHERE r.status = 'paid' 
GROUP BY u.user_id, u.phone_number, u.email 
HAVING COUNT(DISTINCT t.sport_type) = (SELECT COUNT(DISTINCT sport_type) FROM tickets);

-- 15. Tickets purchased today ordered by payment time
SELECT t.*, p.paid_at 
FROM tickets t 
JOIN reservations r ON t.ticket_id = r.ticket_id 
JOIN payments p ON r.reservation_id = p.reservation_id 
WHERE p.status = 'successful' AND DATE(p.paid_at) = CURRENT_DATE 
ORDER BY p.paid_at ASC;

-- 16. Second most popular / top-selling ticket overall
SELECT t.*, COUNT(r.reservation_id) AS sold_count 
FROM tickets t 
JOIN reservations r ON t.ticket_id = r.ticket_id 
WHERE r.status = 'paid' 
GROUP BY t.ticket_id 
ORDER BY sold_count DESC 
OFFSET 1 LIMIT 1;

-- 17. Support agent with highest number of cancellations and their percentage
SELECT u.full_name, COUNT(r.reservation_id) AS cancel_count, 
       (COUNT(r.reservation_id) * 100.0 / NULLIF((SELECT COUNT(*) FROM reservations WHERE status = 'cancelled'), 0)) AS cancel_percentage 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
WHERE u.role = 'support' AND r.status = 'cancelled' 
GROUP BY u.user_id, u.full_name 
ORDER BY cancel_count DESC 
LIMIT 1;

-- 18. Surname/Full name of user with the highest rejected cancellation requests
SELECT u.full_name 
FROM users u 
JOIN reports rep ON u.user_id = rep.user_id 
WHERE rep.status = 'rejected' 
GROUP BY u.user_id, u.full_name 
ORDER BY COUNT(rep.report_id) DESC 
LIMIT 1;

-- 19. Delete all cancelled reservations belonging to rejected users
DELETE FROM reservations 
WHERE status = 'cancelled' 
  AND user_id IN (SELECT user_id FROM reports WHERE status = 'rejected');

-- 20. Clear all cancelled reservations in the system
DELETE FROM reservations 
WHERE status = 'cancelled';

-- 21. Discount ticket prices by 10% for unsold tickets at Azadi Stadium on match days
UPDATE tickets 
SET price = price * 0.90 
WHERE venue_name ILIKE '%Azadi%' 
  AND remaining_capacity > 0
  AND DATE(match_date) = CURRENT_DATE;

-- 22. Report category and count for the reservation with the highest number of complaints
SELECT category, COUNT(report_id) AS report_count 
FROM reports 
WHERE reservation_id = (
    SELECT reservation_id 
    FROM reports 
    GROUP BY reservation_id 
    ORDER BY COUNT(report_id) DESC 
    LIMIT 1
) 
GROUP BY category;

-- 23. Optimized query for upcoming match lookups leveraging B-Tree index
SELECT * FROM tickets 
WHERE sport_type = 'football' AND city = 'Tehran' AND match_date >= CURRENT_TIMESTAMP 
ORDER BY match_date ASC;


-- =============================================================================
-- PART 2: 8 PL/pgSQL Stored Procedures / Functions
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

-- 2. Get list of cancelled reservations handled by a specific support contact
CREATE OR REPLACE FUNCTION get_cancelled_reservations_by_support(p_contact VARCHAR)
RETURNS TABLE(reservation_id INT, user_id INT, ticket_id INT) AS $$
BEGIN
    RETURN QUERY
    SELECT r.reservation_id, r.user_id, r.ticket_id
    FROM reservations r
    JOIN users u ON r.user_id = u.user_id
    WHERE (u.phone_number = p_contact OR u.email = p_contact) 
      AND u.role = 'support' 
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