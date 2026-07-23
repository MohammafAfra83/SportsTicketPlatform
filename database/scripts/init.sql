-- =============================================================================
-- Database Project: Seed Data Script (DML) - Iranian Sports Ticket Platform
-- فایل داده‌های اولیه (DML) - سامانه رزرو بلیط مسابقات ورزشی (نسخه تواریخ پویا)
-- Database Engine: PostgreSQL (UTF-8 Encoded / پشتیبانی کامل از فارسی و انگلیسی)
-- =============================================================================

-- 1. Insert Sample Users (Audience and Support)
INSERT INTO users (full_name, phone_number, email, password_hash, role, city) VALUES
('علی محمدی (Ali Mohammadi)', '09121111111', 'ali@example.com', '$2b$12$eW8...hash1', 'audience', 'Tehran'),
('رضا احمدی (Reza Ahmadi)', '09122222222', 'reza@example.com', '$2b$12$eW8...hash2', 'audience', 'Tehran'),
('مریم کاظمی (Maryam Kazemi)', '09123333333', 'maryam@example.com', '$2b$12$eW8...hash3', 'audience', 'Isfahan'),
('Sara Hosseini (سارا حسینی)', '09124444444', 'sara@example.com', '$2b$12$eW8...hash4', 'audience', 'Shiraz'),
('Mohammad Karimi (محمد کریمی)', '09125555555', 'mohammad@example.com', '$2b$12$eW8...hash5', 'audience', 'Tabriz'),
('حسین رضایی (Hossein Rezaei)', '09126666666', 'hossein@example.com', '$2b$12$eW8...hash6', 'audience', 'Mashhad'),
('زهرا نوری (Zahra Noori)', '09127777777', 'zahra@example.com', '$2b$12$eW8...hash7', 'audience', 'Tehran'),
('مهدی قاسمی (Mahdi Ghasemi)', '09128888888', 'mahdi@example.com', '$2b$12$eW8...hash8', 'audience', 'Isfahan'),
('امیر باقری (Amir Bagheri)', '09129999999', 'amir@example.com', '$2b$12$eW8...hash9', 'support', 'Tehran'),
('مدیر پشتیبانی (Admin Support)', '09120000000', 'admin@example.com', '$2b$12$eW8...hash10', 'support', 'Tehran');

-- 2. Insert Sample Tickets (Dynamic timestamps for Match Dates)
INSERT INTO tickets (title, sport_type, organizer, venue_name, city, match_date, price, remaining_capacity) VALUES
('استقلال - پرسپولیس (Esteghlal vs Persepolis)', 'football', 'سازمان لیگ (Pro League)', 'Azadi Stadium / ورزشگاه آزادی', 'Tehran', CURRENT_TIMESTAMP, 150000.00, 500),
('سپاهان - تراکتور (Sepahan vs Tractor)', 'football', 'سازمان لیگ (Pro League)', 'Naghsh-e Jahan Stadium / ورزشگاه نقش جهان', 'Isfahan', CURRENT_TIMESTAMP + INTERVAL '2 days', 100000.00, 300),
('ایران - ژاپن (Iran vs Japan)', 'volleyball', 'فدراسیون والیبال (Volleyball Fed)', '12k Azadi Hall / سالن ۱۲ هزار نفری آزادی', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '5 days', 120000.00, 200),
('پیکان - شهداب (Paykan vs Shahdab)', 'volleyball', 'فدراسیون والیبال (Volleyball Fed)', 'Federation Hall / سالن فدراسیون', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '8 days', 80000.00, 150),
('شهرداری گرگان - کاله (Gorgan vs Kalleh)', 'basketball', 'فدراسیون بسکتبال (Basketball Fed)', 'Imam Khomeini Hall / سالن امام خمینی', 'Gorgan', CURRENT_TIMESTAMP + INTERVAL '10 days', 90000.00, 100),
('مهرام - ذوب آهن (Mahram vs Zob Ahan)', 'basketball', 'فدراسیون بسکتبال (Basketball Fed)', 'Azadi Hall / سالن آزادی', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '12 days', 85000.00, 120),
('فولاد - گل گهر (Foolad vs Gol Gohar)', 'football', 'سازمان لیگ (Pro League)', 'Foolad Arena / ورزشگاه فولاد آرنا', 'Ahvaz', CURRENT_TIMESTAMP + INTERVAL '15 days', 70000.00, 400),
('Iran vs Poland (ایران - لهستان)', 'volleyball', 'فدراسیون والیبال (Volleyball Fed)', '12k Azadi Hall / سالن ۱۲ هزار نفری آزادی', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '18 days', 200000.00, 50),
('طبیعت - نفت آبادان (Nature vs Naft)', 'basketball', 'فدراسیون بسکتبال (Basketball Fed)', 'Azadi Hall / سالن آزادی', 'Tehran', CURRENT_TIMESTAMP + INTERVAL '20 days', 60000.00, 80),
('ملوان - نساجی (Malavan vs Nassaji)', 'football', 'سازمان لیگ (Pro League)', 'Sirous Ghayeghran Stadium / ورزشگاه سیروس قایقران', 'Anzali', CURRENT_TIMESTAMP + INTERVAL '25 days', 50000.00, 250);

-- 3. Insert Specific Sport Details (3NF Extensions)
INSERT INTO football_details VALUES 
(1, 'لیگ برتر خلیج فارس (Persian Gulf Pro League)', 'جایگاه اصلی (Main Stand)', 5, 12, true, true),
(2, 'لیگ برتر خلیج فارس (Persian Gulf Pro League)', 'جایگاه جنوبی (South Stand)', 10, 45, false, false),
(7, 'لیگ برتر خلیج فارس (Persian Gulf Pro League)', 'پاویون ویژه (VIP Lounge)', 2, 5, true, true),
(10, 'لیگ برتر خلیج فارس (Persian Gulf Pro League)', 'جایگاه شمالی (North Stand)', 8, 20, false, false);

INSERT INTO volleyball_details VALUES 
(3, 'لیگ ملت‌های آسیا (Asian Nations League)', 'سالن ۱۲ هزار نفری (12k Hall)', true, 'A1', 3, 14),
(4, 'لیگ برتر والیبال (Premier League)', 'سالن فدراسیون (Federation Hall)', true, 'B2', 6, 8),
(8, 'جام جهانی والیبال (World Cup)', 'سالن ۱۲ هزار نفری (12k Hall)', true, 'VIP', 1, 2);

INSERT INTO basketball_details VALUES 
(5, 'سوپر لیگ بسکتبال (Super League)', 'سالن امام خمینی (Imam Khomeini Hall)', true, 'C1', 2, 4),
(6, 'سوپر لیگ بسکتبال (Super League)', 'سالن آزادی (Azadi Hall)', false, 'A2', 5, 10),
(9, 'سوپر لیگ بسکتبال (Super League)', 'سالن آزادی (Azadi Hall)', false, 'B1', 4, 12);

-- 4. Insert Sample Reservations (Dynamic Timestamps for Relative Queries)
INSERT INTO reservations (user_id, ticket_id, status, reserved_at, expires_at) VALUES
(1, 1, 'paid', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
(1, 3, 'paid', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '10 minutes'),
(1, 5, 'paid', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '5 days' + INTERVAL '10 minutes'),
(2, 3, 'pending', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '10 minutes'),
(3, 2, 'paid', CURRENT_TIMESTAMP - INTERVAL '10 days', CURRENT_TIMESTAMP - INTERVAL '10 days' + INTERVAL '10 minutes'),
(4, 8, 'cancelled', CURRENT_TIMESTAMP - INTERVAL '12 days', CURRENT_TIMESTAMP - INTERVAL '12 days' + INTERVAL '10 minutes'),
(5, 1, 'cancelled', CURRENT_TIMESTAMP - INTERVAL '15 days', CURRENT_TIMESTAMP - INTERVAL '15 days' + INTERVAL '10 minutes'),
(9, 4, 'cancelled', CURRENT_TIMESTAMP - INTERVAL '18 days', CURRENT_TIMESTAMP - INTERVAL '18 days' + INTERVAL '10 minutes');

-- 5. Insert Sample Payments (Dynamic Timestamps matching Reservations)
INSERT INTO payments (reservation_id, user_id, amount, status, payment_method, paid_at) VALUES
(1, 1, 150000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(2, 1, 120000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(3, 1, 90000.00, 'successful', 'wallet', CURRENT_TIMESTAMP - INTERVAL '5 days'),
(5, 3, 100000.00, 'successful', 'online_gateway', CURRENT_TIMESTAMP - INTERVAL '10 days');

-- 6. Insert Sample Reports
INSERT INTO reports (user_id, reservation_id, category, report_text, status) VALUES
(4, 6, 'مشکل لغو رزرو (Cancellation Issue)', 'درخواست لغو رزرو به دلیل تاخیر در زمان مسابقه.', 'rejected'),
(5, 7, 'خطای درگاه پرداخت (Payment Gateway Error)', 'Money deducted but ticket not issued / مبلغ کسر شد اما بلیط صادر نگردید.', 'under_review'),
(4, 6, 'تداخل صندلی (Seat Conflict)', 'Selected seat was already occupied / صندلی انتخاب شده قبلاً فروخته شده بود.', 'rejected'),
(2, 4, 'مغایرت قیمت (Price Discrepancy)', 'قیمت بلیط با تابلوی ورودی سالن مغایرت داشت.', 'resolved');