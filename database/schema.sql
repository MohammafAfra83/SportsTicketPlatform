-- حذف جداول قبلی در صورت وجود (برای اجرای تمیز اسکریپت)
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS basketball_details CASCADE;
DROP TABLE IF EXISTS volleyball_details CASCADE;
DROP TABLE IF EXISTS football_details CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS reservation_status CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;

-- ایجاد انواعی از داده‌های ENUM
CREATE TYPE user_role AS ENUM ('audience', 'support');
CREATE TYPE reservation_status AS ENUM ('pending', 'paid', 'cancelled');
CREATE TYPE payment_status AS ENUM ('successful', 'failed', 'pending');

-- ۱. جدول کاربران (تماشاگران و پشتیبانان)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL, -- محدودیت یکتایی شماره تماس
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,    -- رمز عبور هش‌شده
    role user_role DEFAULT 'audience',
    city VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ۲. جدول کلی بلیط‌ها و مسابقات
CREATE TABLE tickets (
    ticket_id SERIAL PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    sport_type VARCHAR(50) NOT NULL CHECK (sport_type IN ('football', 'volleyball', 'basketball')),
    organizer VARCHAR(100) NOT NULL,
    venue_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    match_date TIMESTAMP NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0), -- محدودیت قیمت غیرمنفی
    remaining_capacity INT NOT NULL CHECK (remaining_capacity >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ۳. جزئیات اختصاصی مسابقات فوتبال
CREATE TABLE football_details (
    ticket_id INT PRIMARY KEY REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    league_name VARCHAR(100) NOT NULL,
    stand_section VARCHAR(50) NOT NULL, -- بخش سکو
    row_number INT NOT NULL,
    seat_number INT NOT NULL,
    is_vip BOOLEAN DEFAULT FALSE,
    parking_access BOOLEAN DEFAULT FALSE
);

-- ۴. جزئیات اختصاصی مسابقات والیبال
CREATE TABLE volleyball_details (
    ticket_id INT PRIMARY KEY REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    tournament_name VARCHAR(100) NOT NULL,
    hall_name VARCHAR(100) NOT NULL,
    is_indoor BOOLEAN DEFAULT TRUE,     -- سالن مسقف
    seat_section VARCHAR(50) NOT NULL,
    row_number INT NOT NULL,
    seat_number INT NOT NULL
);

-- ۵. جزئیات اختصاصی مسابقات بسکتبال
CREATE TABLE basketball_details (
    ticket_id INT PRIMARY KEY REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    league_name VARCHAR(100) NOT NULL,
    hall_name VARCHAR(100) NOT NULL,
    court_side_access BOOLEAN DEFAULT FALSE, -- دسترسی به کنار زمین
    seat_section VARCHAR(50) NOT NULL,
    row_number INT NOT NULL,
    seat_number INT NOT NULL
);

-- ۶. جدول رزروها
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    ticket_id INT NOT NULL REFERENCES tickets(ticket_id) ON DELETE CASCADE,
    status reservation_status DEFAULT 'pending',
    reserved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    CONSTRAINT check_reservation_dates CHECK (reserved_at < expires_at) -- منطق تاریخ رزرو و انقضا
);

-- ۷. جدول تراکنش‌های مالی و پرداخت
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    reservation_id INT UNIQUE NOT NULL REFERENCES reservations(reservation_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    status payment_status DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'online_gateway',
    paid_at TIMESTAMP
);

-- ۸. جدول گزارشات و تخلفات
CREATE TABLE reports (
    report_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    reservation_id INT REFERENCES reservations(reservation_id) ON DELETE SET NULL,
    category VARCHAR(100) NOT NULL,
    report_text TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'under_review', -- در انتظار بررسی، بررسی‌شده
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ایجاد ایندکس‌ها برای بهینه‌سازی سرعت کوئری‌ها
CREATE INDEX idx_tickets_sport_city ON tickets(sport_type, city);
CREATE INDEX idx_tickets_match_date ON tickets(match_date);
CREATE INDEX idx_reservations_user ON reservations(user_id);