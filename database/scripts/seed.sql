-- =============================================================================
-- Database Project: Seed Data Script (DML) - Full Dataset 
-- File: seed.sql
-- Database Engine: PostgreSQL
-- =============================================================================

-- 1. Insert Sample Users (10 Records)
INSERT INTO users (first_name, last_name, phone_number, email, password_hash, role, city) VALUES
('Ali', 'Mohammadi (علی محمدی)', '09121111111', 'ali@example.com', '$2b$12$eW8...hash1', 'audience', 'Tehran'),
('Reza', 'Ahmadi (رضا احمدی)', '09122222222', 'reza@example.com', '$2b$12$eW8...hash2', 'audience', 'Tehran'),
('Maryam', 'Kazemi (مریم کاظمی)', '09123333333', 'maryam@example.com', '$2b$12$eW8...hash3', 'audience', 'Isfahan'),
('Sara', 'Hosseini (سارا حسینی)', '09124444444', 'sara@example.com', '$2b$12$eW8...hash4', 'audience', 'Shiraz'),
('Mohammad', 'Karimi (محمد کریمی)', '09125555555', 'mohammad@example.com', '$2b$12$eW8...hash5', 'audience', 'Tabriz'),
('Hossein', 'Rezaei (حسین رضایی)', '09126666666', 'hossein@example.com', '$2b$12$eW8...hash6', 'audience', 'Mashhad'),
('Zahra', 'Noori (زهرا نوری)', '09127777777', 'zahra@example.com', '$2b$12$eW8...hash7', 'audience', 'Tehran'),
('Mahdi', 'Ghasemi (مهدی قاسمی)', '09128888888', 'mahdi@example.com', '$2b$12$eW8...hash8', 'audience', 'Isfahan'),
('Amir', 'Bagheri (امیر باقری)', '09129999999', 'amir@example.com', '$2b$12$eW8...hash9', 'support', 'Tehran'),
('Admin', 'Support (مدیر پشتیبانی)', '09120000000', 'admin@example.com', '$2b$12$eW8...hash10', 'support', 'Tehran');

-- 2. Insert Sample Tickets (30 Records)
INSERT INTO tickets (home_team, away_team, sport_type, ticket_tier, organizer, venue_name, city, match_date, price, remaining_capacity) VALUES
('Esteghlal', 'Persepolis', 'football', 'VIP', 'سازمان لیگ', 'Azadi Stadium', 'Tehran', CURRENT_TIMESTAMP, 150000.00, 500),
('Sepahan', 'Tractor', 'football', 'Regular', 'سازمان لیگ', 'Naghsh-e Jahan', 'Isfahan', CURRENT_TIMESTAMP + INTERVAL '2 days', 100000.00, 300),
('Iran', 'Japan', 'volleyball', 'VVIP', 'فدراسیون والیبال', '12k Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '5 days', 120000.00, 200),
('Paykan', 'Shahdab', 'volleyball', 'Regular', 'فدراسیون والیبال', 'Federation Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '8 days', 80000.00, 150),
('Gorgan', 'Kalleh', 'basketball', 'VIP', 'فدراسیون بسکتبال', 'Imam Khomeini Hall', 'Gorgan', CURRENT_TIMESTAMP + INTERVAL '10 days', 90000.00, 100),
('Mahram', 'Zob Ahan', 'basketball', 'Regular', 'فدراسیون بسکتبال', 'Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '12 days', 85000.00, 120),
('Foolad', 'Gol Gohar', 'football', 'Regular', 'سازمان لیگ', 'Foolad Arena', 'Ahvaz', CURRENT_TIMESTAMP + INTERVAL '15 days', 70000.00, 400),
('Iran', 'Poland', 'volleyball', 'VIP', 'فدراسیون والیبال', '12k Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '18 days', 200000.00, 50),
('Nature', 'Naft', 'basketball', 'Regular', 'فدراسیون بسکتبال', 'Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '20 days', 60000.00, 80),
('Malavan', 'Nassaji', 'football', 'Regular', 'سازمان لیگ', 'Sirous Ghayeghran', 'Anzali', CURRENT_TIMESTAMP + INTERVAL '25 days', 50000.00, 250),
('Mes Rafsanjan', 'Esteghlal Khuzestan', 'football', 'Regular', 'سازمان لیگ', 'Shohadaye Mes', 'Rafsanjan', CURRENT_TIMESTAMP + INTERVAL '10 days', 40000.00, 200),
('Aluminum Arak', 'Paykan', 'football', 'Regular', 'سازمان لیگ', 'Imam Khomeini', 'Arak', CURRENT_TIMESTAMP + INTERVAL '12 days', 45000.00, 150),
('Shams Azar', 'Zob Ahan', 'football', 'Regular', 'سازمان لیگ', 'Sardar Azadegan', 'Qazvin', CURRENT_TIMESTAMP + INTERVAL '14 days', 50000.00, 180),
('Sanat Naft', 'Havadar', 'football', 'Regular', 'سازمان لیگ', 'Takhti', 'Abadan', CURRENT_TIMESTAMP + INTERVAL '16 days', 35000.00, 300),
('Esteghlal', 'Sepahan', 'football', 'VIP', 'سازمان لیگ', 'Azadi Stadium', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '30 days', 200000.00, 800),
('Tractor', 'Persepolis', 'football', 'VIP', 'سازمان لیگ', 'Yadegar-e Emam', 'Tabriz', CURRENT_TIMESTAMP + INTERVAL '35 days', 150000.00, 700),
('Shahrdari Urmia', 'Giti Pasand', 'volleyball', 'Regular', 'فدراسیون والیبال', 'Ghadir Hall', 'Urmia', CURRENT_TIMESTAMP + INTERVAL '20 days', 60000.00, 100),
('Eefa Ceram', 'Nian Electronic', 'volleyball', 'Regular', 'فدراسیون والیبال', 'Ardakan Hall', 'Yazd', CURRENT_TIMESTAMP + INTERVAL '22 days', 55000.00, 120),
('Pas Gorgan', 'Hoorasan', 'volleyball', 'Regular', 'فدراسیون والیبال', 'Imam Khomeini Hall', 'Gorgan', CURRENT_TIMESTAMP + INTERVAL '24 days', 50000.00, 150),
('Saipa', 'Mes Rafsanjan', 'volleyball', 'Regular', 'فدراسیون والیبال', 'Khane Volleyball', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '26 days', 65000.00, 200),
('Chadormalu', 'Shahrdari Gonbad', 'volleyball', 'Regular', 'فدراسیون والیبال', 'Ardakan Hall', 'Yazd', CURRENT_TIMESTAMP + INTERVAL '28 days', 50000.00, 100),
('Iran', 'Brazil', 'volleyball', 'VVIP', 'فدراسیون جهانی', '12k Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '40 days', 250000.00, 500),
('Iran', 'Italy', 'volleyball', 'VVIP', 'فدراسیون جهانی', '12k Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '45 days', 250000.00, 500),
('Palayesh Naft', 'Kalleh', 'basketball', 'Regular', 'فدراسیون بسکتبال', 'Takhti Hall', 'Abadan', CURRENT_TIMESTAMP + INTERVAL '30 days', 70000.00, 100),
('Zob Ahan', 'Shahrdari Gorgan', 'basketball', 'VIP', 'فدراسیون بسکتبال', 'Mellat Hall', 'Isfahan', CURRENT_TIMESTAMP + INTERVAL '32 days', 80000.00, 150),
('Limondis', 'Mes Kerman', 'basketball', 'Regular', 'فدراسیون بسکتبال', 'Sadra Hall', 'Shiraz', CURRENT_TIMESTAMP + INTERVAL '34 days', 65000.00, 120),
('Mahram', 'Tabiat', 'basketball', 'VIP', 'فدراسیون بسکتبال', 'Shahr-e Qods Hall', 'Shahr-e Qods', CURRENT_TIMESTAMP + INTERVAL '36 days', 75000.00, 200),
('Avarata', 'Raad Padafand', 'basketball', 'Regular', 'فدراسیون بسکتبال', 'Shahid Beheshti', 'Mashhad', CURRENT_TIMESTAMP + INTERVAL '38 days', 55000.00, 100),
('Iran', 'Lebanon', 'basketball', 'VVIP', 'فیبا آسیا', 'Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '50 days', 150000.00, 300),
('Iran', 'China', 'basketball', 'VVIP', 'فیبا آسیا', 'Azadi Hall', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '55 days', 180000.00, 300);

-- 3. Insert Specific Sport Details (30 Records)
INSERT INTO football_details (ticket_id, league_name, stadium_name, stand_section, row_number, seat_number, ticket_type, amenities) VALUES 
(1, 'لیگ برتر خلیج فارس', 'Azadi Stadium', 'جایگاه اصلی', 5, 12, 'Electronic', 'VIP, Parking Access'),
(2, 'لیگ برتر خلیج فارس', 'Naghsh-e Jahan', 'جایگاه جنوبی', 10, 45, 'Paper', 'None'),
(7, 'لیگ برتر خلیج فارس', 'Foolad Arena', 'پاویون ویژه', 2, 5, 'Electronic', 'VIP, Parking Access'),
(10, 'لیگ برتر خلیج فارس', 'Sirous Ghayeghran', 'جایگاه شمالی', 8, 20, 'Paper', 'None'),
(11, 'لیگ آزادگان', 'Shohadaye Mes', 'جایگاه A', 3, 10, 'Electronic', 'Parking Access'),
(12, 'لیگ برتر خلیج فارس', 'Imam Khomeini', 'جایگاه B', 4, 15, 'Paper', 'None'),
(13, 'لیگ برتر خلیج فارس', 'Sardar Azadegan', 'جایگاه C', 6, 25, 'Electronic', 'Parking Access'),
(14, 'لیگ برتر خلیج فارس', 'Takhti', 'جایگاه VIP', 1, 2, 'Electronic', 'VIP, Parking Access'),
(15, 'لیگ برتر خلیج فارس', 'Azadi Stadium', 'جایگاه اصلی', 12, 100, 'Electronic', 'VIP, Parking Access'),
(16, 'لیگ برتر خلیج فارس', 'Yadegar-e Emam', 'جایگاه روبرو', 15, 200, 'Paper', 'None');

INSERT INTO volleyball_details (ticket_id, league_name, hall_name, seat_section, row_number, seat_number, ticket_tier, amenities) VALUES 
(3, 'لیگ ملت‌های آسیا', '12k Azadi Hall', 'A1', 3, 14, 'Gold', 'Indoor'),
(4, 'لیگ برتر والیبال', 'Federation Hall', 'B2', 6, 8, 'Silver', 'Indoor'),
(8, 'جام جهانی والیبال', '12k Azadi Hall', 'VIP', 1, 2, 'Gold', 'Indoor, Parking'),
(17, 'لیگ برتر والیبال', 'Ghadir Hall', 'C1', 4, 12, 'Bronze', 'Indoor'),
(18, 'لیگ برتر والیبال', 'Ardakan Hall', 'A3', 2, 5, 'Silver', 'Indoor'),
(19, 'لیگ برتر والیبال', 'Imam Khomeini Hall', 'B1', 7, 20, 'Silver', 'Indoor'),
(20, 'لیگ برتر والیبال', 'Khane Volleyball', 'C2', 5, 15, 'Bronze', 'Indoor'),
(21, 'لیگ برتر والیبال', 'Ardakan Hall', 'A2', 3, 9, 'Silver', 'Indoor'),
(22, 'لیگ جهانی', '12k Azadi Hall', 'VIP', 1, 5, 'Gold', 'Indoor, VIP'),
(23, 'لیگ جهانی', '12k Azadi Hall', 'VIP', 1, 6, 'Gold', 'Indoor, VIP');

INSERT INTO basketball_details (ticket_id, league_name, hall_name, seat_section, row_number, seat_number, ticket_tier, amenities) VALUES 
(5, 'سوپر لیگ بسکتبال', 'Imam Khomeini Hall', 'C1', 2, 4, 'Gold', 'Court Side Access'),
(6, 'سوپر لیگ بسکتبال', 'Azadi Hall', 'A2', 5, 10, 'Silver', 'None'),
(9, 'سوپر لیگ بسکتبال', 'Azadi Hall', 'B1', 4, 12, 'Bronze', 'None'),
(24, 'سوپر لیگ بسکتبال', 'Takhti Hall', 'D1', 3, 11, 'Bronze', 'None'),
(25, 'سوپر لیگ بسکتبال', 'Mellat Hall', 'VIP', 1, 1, 'Gold', 'Court Side Access'),
(26, 'سوپر لیگ بسکتبال', 'Sadra Hall', 'A1', 6, 22, 'Silver', 'None'),
(27, 'سوپر لیگ بسکتبال', 'Shahr-e Qods Hall', 'B2', 5, 18, 'Gold', 'None'),
(28, 'سوپر لیگ بسکتبال', 'Shahid Beheshti', 'C2', 8, 30, 'Bronze', 'None'),
(29, 'کاپ آسیا', 'Azadi Hall', 'CourtSide', 1, 3, 'Gold', 'Court Side Access'),
(30, 'کاپ آسیا', 'Azadi Hall', 'CourtSide', 1, 4, 'Gold', 'Court Side Access');

-- 4. Insert Sample Reservations (MODIFIED to create Rank 1 and Rank 2 tickets)
INSERT INTO reservations (user_id, ticket_id, status, reserved_at, expires_at, cancelled_by_support_id) VALUES
(1, 1, 'paid', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP + INTERVAL '1 day', NULL),  -- Ticket 1 (Sale 1)
(2, 1, 'paid', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP + INTERVAL '1 day', NULL),   -- Ticket 1 (Sale 2)
(3, 1, 'paid', CURRENT_TIMESTAMP - INTERVAL '5 hours', CURRENT_TIMESTAMP + INTERVAL '1 day', NULL), -- Ticket 1 (Sale 3) -> Rank 1
(4, 2, 'paid', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP + INTERVAL '1 day', NULL),  -- Ticket 2 (Sale 1)
(5, 2, 'paid', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP + INTERVAL '1 day', NULL), -- Ticket 2 (Sale 2) -> Rank 2
(6, 3, 'paid', CURRENT_TIMESTAMP - INTERVAL '20 days', CURRENT_TIMESTAMP - INTERVAL '19 days', NULL),
(7, 4, 'cancelled', CURRENT_TIMESTAMP - INTERVAL '12 days', CURRENT_TIMESTAMP - INTERVAL '11 days', 9),
(8, 5, 'cancelled', CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP - INTERVAL '14 days', 10),
(1, 9, 'paid', CURRENT_TIMESTAMP - INTERVAL '22 days', CURRENT_TIMESTAMP - INTERVAL '21 days', NULL),
(2, 11, 'paid', CURRENT_TIMESTAMP - INTERVAL '25 days', CURRENT_TIMESTAMP - INTERVAL '24 days', NULL),
(3, 15, 'pending', CURRENT_TIMESTAMP - INTERVAL '1 hour', CURRENT_TIMESTAMP + INTERVAL '23 hours', NULL),
(4, 29, 'cancelled', CURRENT_TIMESTAMP - INTERVAL '28 days', CURRENT_TIMESTAMP - INTERVAL '27 days', 9);

-- 5. Insert Sample Payments (Aligned with Reservations)
INSERT INTO payments (reservation_id, user_id, amount, status, payment_method, paid_at) VALUES
(1, 1, 150000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(2, 2, 150000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(3, 3, 150000.00, 'successful', 'wallet', CURRENT_TIMESTAMP - INTERVAL '5 hours'),
(4, 4, 100000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(5, 5, 100000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '10 days'),
(6, 6, 120000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '20 days'),
(9, 1, 60000.00, 'successful', 'wallet', CURRENT_TIMESTAMP - INTERVAL '22 days'),
(10, 2, 40000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '25 days'),
(7, 7, 80000.00, 'failed', 'wallet', CURRENT_TIMESTAMP - INTERVAL '11 days'),
(8, 8, 90000.00, 'failed', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '14 days');

-- 6. Insert Sample Reports
INSERT INTO reports (user_id, ticket_id, reservation_id, category, report_text, status) VALUES
(4, 8, 7, 'Cancellation Issue', 'درخواست لغو رزرو به دلیل تاخیر در زمان مسابقه.', 'under_review'),
(5, 1, 8, 'Payment Gateway Error', 'مبلغ کسر شد اما بلیط صادر نگردید.', 'under_review'),
(4, 8, 7, 'Seat Conflict', 'صندلی انتخاب شده قبلاً فروخته شده بود.', 'resolved'),
(2, 3, 4, 'Price Discrepancy', 'قیمت بلیط با تابلوی ورودی سالن مغایرت داشت.', 'resolved'),
(1, 1, 1, 'Seat Quality', 'صندلی شکسته بود و قابل نشستن نبود.', 'under_review'),
(3, 2, 5, 'Staff Behavior', 'رفتار مامورین چک کردن بلیط محترمانه نبود.', 'resolved'),
(6, 11, 9, 'Start Delay', 'مسابقه با بیش از یک ساعت تاخیر شروع شد.', 'under_review'),
(7, 15, 10, 'Parking Issue', 'با وجود خرید بلیط VIP اجازه ورود به پارکینگ اصلی داده نشد.', 'resolved'),
(8, 22, 11, 'AC Issue', 'تهویه سالن در نیمه اول بسیار ضعیف بود.', 'under_review'),
(1, 3, 2, 'SMS Issue', 'پیامک تایید خرید پس از پرداخت ارسال نشد.', 'resolved');