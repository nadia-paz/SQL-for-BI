-- all payments in February

SELECT p.payment_id, p.customer_id, p.amount, p.payment_date
FROM payment p
WHERE EXTRACT(MONTH FROM p.payment_date) = 2 AND P.AMOUNT > 2;

-- date without time

-- postgres only
SELECT p.payment_date::date
FROM payment p;

-- should work in mysql
SELECT CAST(p.payment_date AS DATE)
FROM payment p;

-- create an array of payment dates for each customer

SELECT customer_id, COUNT(*) AS number_of_orders, SUM(amount), ARRAY_AGG(payment_date)
FROM payment
GROUP BY customer_id;

-- generate dates every other day from NY

SELECT gs::date
FROM generate_series('2024-01-01', current_date::date, INTERVAL '2 DAY') gs;

```
JOINS
```
