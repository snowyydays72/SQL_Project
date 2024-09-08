--Query 1
SELECT c.name AS category_name, 
       f.title AS film_title, 
       COUNT(r.rental_id) AS total_rentals
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name, f.title
ORDER BY total_rentals DESC;

--Query 2
SELECT EXTRACT(YEAR FROM r.rental_date) AS year,
       EXTRACT(MONTH FROM r.rental_date) AS month,
       s.store_id,
       COUNT(r.rental_id) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN store s ON i.store_id = s.store_id
GROUP BY EXTRACT(YEAR FROM r.rental_date), 
         EXTRACT(MONTH FROM r.rental_date), 
         s.store_id
ORDER BY rental_count DESC, year, month, s.store_id;

--Query 3
WITH customer_total_payment AS (
    SELECT c.customer_id,
           CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
           SUM(p.amount) AS total_payment
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
    ORDER BY total_payment DESC
    LIMIT 10
),
monthly_payment AS (
    SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
           TO_CHAR(DATE_TRUNC('month', p.payment_date), 'YYYY-MM-DD') AS payment_month,
           COUNT(p.payment_id) AS payment_count,
           SUM(p.amount) AS monthly_total_payment
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    WHERE c.customer_id IN (SELECT customer_id FROM customer_total_payment)
    GROUP BY customer_name, payment_month
    ORDER BY payment_month, monthly_total_payment DESC
)
SELECT customer_name, 
       payment_month, 
       payment_count, 
       monthly_total_payment
FROM monthly_payment;

--Query 4
WITH customer_total_payment AS (
    SELECT c.customer_id,
           CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
           SUM(p.amount) AS total_payment
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
    ORDER BY total_payment DESC
    LIMIT 10
),
monthly_payment_2007 AS (
    SELECT c.customer_id,
           CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
           EXTRACT(MONTH FROM p.payment_date) AS month,
           SUM(p.amount) AS monthly_total_payment
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2007
    AND c.customer_id IN (SELECT customer_id FROM customer_total_payment)
    GROUP BY c.customer_id, customer_name, EXTRACT(MONTH FROM p.payment_date)
    ORDER BY c.customer_id, EXTRACT(MONTH FROM p.payment_date)
),
monthly_diff AS (
    SELECT customer_id,
           customer_name,
           month,
           monthly_total_payment,
           LAG(monthly_total_payment, 1) OVER (PARTITION BY customer_id ORDER BY month) AS prev_monthly_payment,
           (monthly_total_payment - LAG(monthly_total_payment, 1) OVER (PARTITION BY customer_id ORDER BY month)) AS payment_difference
    FROM monthly_payment_2007
)
SELECT customer_name, 
       month, 
       monthly_total_payment,
       COALESCE(payment_difference, 0) AS payment_difference
FROM monthly_diff
ORDER BY customer_name, month;
