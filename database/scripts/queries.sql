-- =============================================================================
-- Database Project: Analytical SQL Queries
-- File: database/scripts/queries.sql
-- Database Engine: PostgreSQL
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

-- 17. User with highest number of cancellations and their percentage of total cancellations
SELECT 
    u.full_name, 
    COUNT(r.reservation_id) AS cancel_count, 
    ROUND(
        (COUNT(r.reservation_id) * 100.0 / NULLIF((SELECT COUNT(*) FROM reservations WHERE status = 'cancelled'), 0)), 
        2
    ) AS cancel_percentage 
FROM users u 
JOIN reservations r ON u.user_id = r.user_id 
WHERE r.status = 'cancelled' 
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