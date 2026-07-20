-- ==========================================
-- بخش اول: ۲۳ کوئری تحلیلی خواسته‌شده در داکیومنت
-- ==========================================

-- ۱. نام و نام خانوادگی کاربرانی که تا به حال هیچ بلیطی رزرو نکرده‌اند
SELECT full_name FROM users WHERE user_id NOT IN (SELECT DISTINCT user_id FROM reservations);

-- ۲. نام و نام خانوادگی کاربرانی که حداقل یک بلیط خریداری (پرداخت موفق) کرده‌اند
SELECT DISTINCT u.full_name FROM users u JOIN reservations r ON u.user_id = r.user_id JOIN payments p ON r.reservation_id = p.reservation_id WHERE p.status = 'successful';

-- ۳. مجموع پرداخت‌های انجام‌شده توسط هر کاربر در ماه اخیر
SELECT user_id, SUM(amount) AS total_paid FROM payments WHERE status = 'successful' AND paid_at >= CURRENT_TIMESTAMP - INTERVAL '1 month' GROUP BY user_id;

-- ۴. لیست کاربرانی که در هر شهر فقط یک بار بلیط خریداری کرده‌اند
SELECT u.user_id, u.full_name, t.city FROM users u JOIN reservations r ON u.user_id = r.user_id JOIN tickets t ON r.ticket_id = t.ticket_id JOIN payments p ON r.reservation_id = p.reservation_id WHERE p.status = 'successful' GROUP BY u.user_id, u.full_name, t.city HAVING COUNT(r.reservation_id) = 1;

-- ۵. اطلاعات کاربرانی که جدیدترین بلیط را خریداری کرده‌اند
SELECT u.* FROM users u JOIN reservations r ON u.user_id = r.user_id JOIN payments p ON r.reservation_id = p.reservation_id WHERE p.status = 'successful' ORDER BY p.paid_at DESC LIMIT 1;

-- ۶. شماره تلفن و ایمیل کاربرانی که مجموع پرداخت آن‌ها بیشتر از میانگین کل پرداخت‌ها است
SELECT u.phone_number, u.email FROM users u JOIN payments p ON u.user_id = p.user_id WHERE p.status = 'successful' GROUP BY u.user_id, u.phone_number, u.email HAVING SUM(p.amount) > (SELECT AVG(amount) FROM payments WHERE status = 'successful');

-- ۷. تعداد بلیط‌های فروخته‌شده به تفکیک هر نوع مسابقه ورزشی
SELECT t.sport_type, COUNT(r.reservation_id) AS total_sold FROM tickets t JOIN reservations r ON t.ticket_id = r.ticket_id WHERE r.status = 'paid' GROUP BY t.sport_type;

-- ۸. ۳ کاربر با بیشترین خرید بلیط در هفته اخیر
SELECT u.full_name, COUNT(r.reservation_id) AS ticket_count FROM users u JOIN reservations r ON u.user_id = r.user_id WHERE r.status = 'paid' AND r.reserved_at >= CURRENT_TIMESTAMP - INTERVAL '1 week' GROUP BY u.user_id, u.full_name ORDER BY ticket_count DESC LIMIT 3;

-- ۹. تعداد بلیط‌های فروخته‌شده در استان تهران به تفکیک شهر
SELECT t.city, COUNT(r.reservation_id) AS sold_count FROM tickets t JOIN reservations r ON t.ticket_id = r.ticket_id WHERE t.city = 'تهران' AND r.status = 'paid' GROUP BY t.city;

-- ۱۰. نام شهرهایی که قدیمی‌ترین کاربر ثبت‌نام‌شده در سیستم از آنجا خرید داشته است
SELECT DISTINCT t.city FROM tickets t JOIN reservations r ON t.ticket_id = r.ticket_id WHERE r.user_id = (SELECT user_id FROM users ORDER BY created_at ASC LIMIT 1);

-- ۱۱. لیست نام پشتیبانانی که سیستم را مدیریت می‌کنند
SELECT full_name FROM users WHERE role = 'support';

-- ۱۲. نام کاربرانی که حداقل ۲ بلیط خریده‌اند
SELECT u.full_name FROM users u JOIN reservations r ON u.user_id = r.user_id WHERE r.status = 'paid' GROUP BY u.user_id, u.full_name HAVING COUNT(r.reservation_id) >= 2;

-- ۱۳. نام کاربرانی که حداکثر ۲ بار از یک نوع مسابقه خاص (مثلاً فوتبال) خرید داشته‌اند
SELECT u.full_name FROM users u JOIN reservations r ON u.user_id = r.user_id JOIN tickets t ON r.ticket_id = t.ticket_id WHERE t.sport_type = 'football' AND r.status = 'paid' GROUP BY u.user_id, u.full_name HAVING COUNT(r.reservation_id) <= 2;

-- ۱۴. شماره تلفن و ایمیل کاربرانی که از تمام انواع مسابقات ورزشی (فوتبال، والیبال، بسکتبال) خرید کرده‌اند
SELECT u.phone_number, u.email FROM users u JOIN reservations r ON u.user_id = r.user_id JOIN tickets t ON r.ticket_id = t.ticket_id WHERE r.status = 'paid' GROUP BY u.user_id, u.phone_number, u.email HAVING COUNT(DISTINCT t.sport_type) = (SELECT COUNT(DISTINCT sport_type) FROM tickets);

-- ۱۵. اطلاعات بلیط‌های خریداری‌شده امروز به ترتیب ساعت خرید
SELECT t.*, p.paid_at FROM tickets t JOIN reservations r ON t.ticket_id = r.ticket_id JOIN payments p ON r.reservation_id = p.reservation_id WHERE p.status = 'successful' AND DATE(p.paid_at) = CURRENT_DATE ORDER BY p.paid_at ASC;

-- ۱۶. دومین بلیط پرفروش در بین کل بلیط‌ها
SELECT t.*, COUNT(r.reservation_id) AS sold_count FROM tickets t JOIN reservations r ON t.ticket_id = r.ticket_id WHERE r.status = 'paid' GROUP BY t.ticket_id ORDER BY sold_count DESC OFFSET 1 LIMIT 1;

-- ۱۷. نام پشتیبان با بیشترین تعداد لغو رزرو بلیط همراه با درصد لغوها
SELECT u.full_name, COUNT(r.reservation_id) AS cancel_count, (COUNT(r.reservation_id) * 100.0 / (SELECT COUNT(*) FROM reservations WHERE status = 'cancelled')) AS cancel_percentage FROM users u JOIN reservations r ON u.user_id = r.user_id WHERE u.role = 'support' AND r.status = 'cancelled' GROUP BY u.user_id, u.full_name ORDER BY cancel_count DESC LIMIT 1;

-- ۱۸. نام خانوادگی کاربری که بیشترین بلیط کنسل‌شده با وضعیت "رد شده" را دارد
SELECT u.full_name FROM users u JOIN reports rep ON u.user_id = rep.user_id WHERE rep.status = 'rejected' GROUP BY u.user_id, u.full_name ORDER BY COUNT(rep.report_id) DESC LIMIT 1;

-- ۱۹. حذف تمام بلیط‌های کنسل‌شده کاربر رد شده
DELETE FROM reservations WHERE status = 'cancelled' AND user_id IN (SELECT user_id FROM reports WHERE status = 'rejected');

-- ۲۰. پاک کردن تمام بلیط‌های کنسل‌شده در سیستم
DELETE FROM reservations WHERE status = 'cancelled';

-- ۲۱. کاهش ۱۰٪ قیمت بلیط‌های فروخته‌نشده در ورزشگاه آزادی برای روزهایی که مسابقه برگزار می‌شود
UPDATE tickets SET price = price * 0.90 WHERE venue_name = 'ورزشگاه آزادی' AND remaining_capacity > 0;

-- ۲۲. موضوع و تعداد گزارش‌ها برای بلیطی با بیشترین تعداد گزارش
SELECT category, COUNT(report_id) AS report_count FROM reports WHERE reservation_id = (SELECT reservation_id FROM reports GROUP BY reservation_id ORDER BY COUNT(report_id) DESC LIMIT 1) GROUP BY category;

-- ۲۳. بهینه‌سازی پردازش‌ها و دسترسی سریع به داده‌ها (نمونه کوئری بهینه‌شده با Index)
SELECT * FROM tickets WHERE sport_type = 'football' AND city = 'تهران' AND match_date >= CURRENT_TIMESTAMP;


-- ==========================================
-- بخش دوم: ۸ تابع ذخیره‌شده (PL/pgSQL Stored Procedures)
-- ==========================================

-- ۱. دریافت لیست بلیط‌های خریداری شده توسط کاربر با دریافت شماره تلفن یا ایمیل
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

-- ۲. دریافت لیست رزروهای لغو شده با دریافت ایمیل یا شماره تلفن پشتیبان
CREATE OR REPLACE FUNCTION get_cancelled_reservations_by_support(p_contact VARCHAR)
RETURNS TABLE(reservation_id INT, user_id INT, ticket_id INT) AS $$
BEGIN
    RETURN QUERY
    SELECT r.reservation_id, r.user_id, r.ticket_id
    FROM reservations r
    JOIN users u ON r.user_id = u.user_id
    WHERE (u.phone_number = p_contact OR u.email = p_contact) AND u.role = 'support' AND r.status = 'cancelled';
END;
$$ LANGUAGE plpgsql;

-- ۳. دریافت لیست نام شهرها و نمایش بلیط‌های خریداری شده در آن شهر
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

-- ۴. جستجوی عبارت در محل برگزاری، هتل‌ها یا رده بلیط‌ها و دریافت بلیط‌ها
CREATE OR REPLACE FUNCTION search_tickets_by_keyword(p_keyword VARCHAR)
RETURNS TABLE(ticket_id INT, title VARCHAR, venue_name VARCHAR, price NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT t.ticket_id, t.title, t.venue_name, t.price
    FROM tickets t
    WHERE t.venue_name ILIKE '%' || p_keyword || '%' OR t.title ILIKE '%' || p_keyword || '%';
END;
$$ LANGUAGE plpgsql;

-- ۵. دریافت شماره تلفن یا ایمیل کاربر و نمایش اطلاعات هم‌شهری‌های او که بلیط خریده‌اند
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

-- ۶. دریافت تاریخ و ورودی n و نمایش لیست کاربران با بیشترین خرید بعد از آن تاریخ
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

-- ۷. دریافت نوع مسابقه ورزشی و نمایش لیست بلیط‌های کنسل‌شده به ترتیب تاریخ
CREATE OR REPLACE FUNCTION get_cancelled_tickets_by_sport(p_sport_type VARCHAR)
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

-- ۸. دریافت موضوع گزارش و نمایش لیست کاربرانی که بیشترین گزارش در آن موضوع دارند
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