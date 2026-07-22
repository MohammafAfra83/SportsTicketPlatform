-- ========================================================
-- Seed Data script for Testing DDL and DML Constraints
-- ========================================================

-- 1. Insert Sample Users (Audience and Support)
INSERT INTO users (full_name, phone_number, email, password_hash, role, city) VALUES
('Ali Mohammadi', '09121111111', 'ali@example.com', '$2b$12$eW8...hash1', 'audience', 'Tehran'),
('Reza Ahmadi', '09122222222', 'reza@example.com', '$2b$12$eW8...hash2', 'audience', 'Tehran'),
('Maryam Kazemi', '09123333333', 'maryam@example.com', '$2b$12$eW8...hash3', 'audience', 'Isfahan'),
('Sara Hosseini', '09124444444', 'sara@example.com', '$2b$12$eW8...hash4', 'audience', 'Shiraz'),
('Mohammad Karimi', '09125555555', 'mohammad@example.com', '$2b$12$eW8...hash5', 'audience', 'Tabriz'),
('Hossein Rezaei', '09126666666', 'hossein@example.com', '$2b$12$eW8...hash6', 'audience', 'Mashhad'),
('Zahra Noori', '09127777777', 'zahra@example.com', '$2b$12$eW8...hash7', 'audience', 'Tehran'),
('Mahdi Ghasemi', '09128888888', 'mahdi@example.com', '$2b$12$eW8...hash8', 'audience', 'Isfahan'),
('Amir Bagheri', '09129999999', 'amir@example.com', '$2b$12$eW8...hash9', 'support', 'Tehran'),
('Admin Support', '09120000000', 'admin@example.com', '$2b$12$eW8...hash10', 'support', 'Tehran');

-- 2. Insert Sample Tickets (Supports UTF-8 Persian/English Titles)
INSERT INTO tickets (title, sport_type, organizer, venue_name, city, match_date, price, remaining_capacity) VALUES
('استقلال - پرسپولیس', 'football', 'Pro League', 'Azadi Stadium', 'Tehran', '2026-08-10 18:00:00', 150000.00, 500),
('سپاهان - تراکتور', 'football', 'Pro League', 'Naghsh-e Jahan Stadium', 'Isfahan', '2026-08-12 17:00:00', 100000.00, 300),
('ایران - ژاپن', 'volleyball', 'Volleyball Federation', '12k Azadi Hall', 'Tehran', '2026-08-15 20:00:00', 120000.00, 200),
('Paykan vs Shahdab', 'volleyball', 'Volleyball Federation', 'Federation Hall', 'Tehran', '2026-08-18 16:00:00', 80000.00, 150),
('Shahrdari Gorgan vs Kalleh', 'basketball', 'Basketball Federation', 'Imam Khomeini Hall', 'Gorgan', '2026-08-20 16:00:00', 90000.00, 100),
('Mahram vs Zob Ahan', 'basketball', 'Basketball Federation', 'Azadi Hall', 'Tehran', '2026-08-22 18:00:00', 85000.00, 120),
('Foolad vs Gol Gohar', 'football', 'Pro League', 'Foolad Arena', 'Ahvaz', '2026-08-25 19:30:00', 70000.00, 400),
('Iran vs Poland', 'volleyball', 'Volleyball Federation', '12k Azadi Hall', 'Tehran', '2026-08-28 19:00:00', 200000.00, 50),
('Nature vs Naft Abadan', 'basketball', 'Basketball Federation', 'Azadi Hall', 'Tehran', '2026-08-30 15:00:00', 60000.00, 80),
('Malavan vs Nassaji', 'football', 'Pro League', 'Sirous Ghayeghran Stadium', 'Anzali', '2026-09-02 17:30:00', 50000.00, 250);

-- 3. Insert Specific Sport Details (3NF) - COMPLETED FOR ALL 10 TICKETS
-- Football Tickets: 1, 2, 7, 10
INSERT INTO football_details VALUES 
(1, 'Persian Gulf Pro League', 'Main Stand', 5, 12, true, true),
(2, 'Persian Gulf Pro League', 'South Stand', 10, 45, false, false),
(7, 'Persian Gulf Pro League', 'VIP Lounge', 2, 5, true, true),
(10, 'Persian Gulf Pro League', 'North Stand', 8, 20, false, false);

-- Volleyball Tickets: 3, 4, 8
INSERT INTO volleyball_details VALUES 
(3, 'Asian Nations League', '12k Hall', true, 'A1', 3, 14),
(4, 'Premier League', 'Federation Hall', true, 'B2', 6, 8),
(8, 'World Cup', '12k Hall', true, 'VIP', 1, 2);

-- Basketball Tickets: 5, 6, 9
INSERT INTO basketball_details VALUES 
(5, 'Super League', 'Imam Khomeini Hall', true, 'C1', 2, 4),
(6, 'Super League', 'Azadi Hall', false, 'A2', 5, 10),
(9, 'Super League', 'Azadi Hall', false, 'B1', 4, 12);
-- ========================================================
-- COMPLETED SEED DATA FOR RESERVATIONS, PAYMENTS & REPORTS
-- ========================================================

-- 4. Insert Sample Reservations (Testing diverse statuses & users)
INSERT INTO reservations (user_id, ticket_id, status, reserved_at, expires_at) VALUES
(1, 1, 'paid', '2026-07-01 10:00:00', '2026-07-01 10:10:00'),
(1, 3, 'paid', '2026-07-02 12:00:00', '2026-07-02 12:10:00'),
(1, 5, 'paid', '2026-07-03 14:00:00', '2026-07-03 14:10:00'), -- User 1 bought football, volleyball, basketball (Tests Query 14)
(2, 3, 'pending', '2026-07-01 11:00:00', '2026-07-01 11:10:00'),
(3, 2, 'paid', '2026-07-04 15:00:00', '2026-07-04 15:10:00'),
(4, 8, 'cancelled', '2026-07-05 09:00:00', '2026-07-05 09:10:00'),
(5, 1, 'cancelled', '2026-07-06 16:00:00', '2026-07-06 16:10:00'),
(9, 4, 'cancelled', '2026-07-07 18:00:00', '2026-07-07 18:10:00');

-- 5. Insert Sample Payments (Testing financial aggregations)
INSERT INTO payments (reservation_id, user_id, amount, status, payment_method, paid_at) VALUES
(1, 1, 150000.00, 'successful', 'online_gateway', '2026-07-01 10:04:00'),
(2, 1, 120000.00, 'successful', 'online_gateway', '2026-07-02 12:05:00'),
(3, 1, 90000.00, 'successful', 'wallet', '2026-07-03 14:02:00'),
(5, 3, 100000.00, 'successful', 'online_gateway', '2026-07-04 15:03:00');

-- 6. Insert Sample Reports (Testing support issues & complaints)
INSERT INTO reports (user_id, reservation_id, category, report_text, status) VALUES
(4, 6, 'Cancellation Issue', 'Requested cancellation due to match delay.', 'rejected'),
(5, 7, 'Payment Gateway Error', 'Money deducted but ticket not issued immediately.', 'under_review'),
(4, 6, 'Seat Conflict', 'Selected seat was already occupied.', 'rejected'),
(2, 4, 'Price Discrepancy', 'Ticket price differs from stadium board.', 'resolved');