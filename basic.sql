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
-- Find movies that never have been renter
-- Have all inventory been rented

SELECT f.film_id, f.title, i.store_id, i.inventory_id, COUNT(DISTINCT r.rental_id) 
FROM film f
LEFT JOIN inventory i USING(film_id)
LEFT JOIN rental r USING(inventory_id)
GROUP BY 1, 2, 3, 4
ORDER BY 5 NULLS FIRST;

```
SELF JOIN
```
-- Find a customer's first rental with rental id and rental date
-- 58ms
SELECT r1.customer_id, MIN(r1.rental_ID) AS first_rental_id, (
	SELECT r2.rental_date FROM rental r2 WHERE r2.rental_id = MIN(r1.rental_ID)
) first_rental_date
FROM rental r1
GROUP BY 1
ORDER BY r1.customer_id;

-- 64ms
WITH first_rent AS (
	SELECT r1.customer_id, MIN(r1.rental_ID) AS first_rental_id
	FROM rental r1
	GROUP BY 1
	ORDER BY r1.customer_id
)
SELECT fr.*, r.rental_date 
FROM first_rent fr
JOIN rental r ON fr.first_rental_id = r.rental_id;

-- How many customers purchased from multiple stores?
-- 78ms
WITH distinct_stores AS (
	SELECT DISTINCT r.customer_id, s.store_id 
	FROM rental r
	LEFT JOIN staff s USING(staff_id)
	ORDER BY 1
)
SELECT ds.customer_id, COUNT(ds.store_id) number_of_stores
FROM distinct_stores ds
GROUP BY 1
HAVING 2 > 1
ORDER BY 1;

-- same without CTE (query plan is the same)
-- 46ms
SELECT t.customer_id, COUNT(*) 
FROM (
	SELECT DISTINCT r.customer_id, s.store_id 
	FROM rental r
	LEFT JOIN staff s USING(staff_id)
	ORDER BY 1
) t
GROUP BY 1
HAVING 2 > 1
ORDER BY 1;

```
common errors
```

-- If NULLs are important move WHERE clause to JOIN condition

-- The there is no data till Feb, 14. 
-- WHERE condition will remove all NULL values from Feb, 1 till Feb, 14

SELECT gs::date, 'just_text', p.* 
FROM generate_series('2007-02-01', '2007-02-28', INTERVAL '1 DAY') gs
LEFT JOIN payment p ON p.payment_date::date = gs::date
WHERE p.staff_id = 2;

-- We keep NULL values when we move the condition to JOIN ON AND

SELECT gs::date, 'just_text', p.* 
FROM generate_series('2007-02-01', '2007-02-28', INTERVAL '1 DAY') gs
LEFT JOIN payment p ON p.payment_date::date = gs::date AND p.staff_id = 2;

-- Find customers who:
--	- made 1st order on weekend
--	- 1st order amount > 5
--	- spent at least 100 total
--Sunday = 0, Saturday=6

-- customers who's first order was on weekend, and worth more than 5 and who spent in total 100
-- my solutions. return 2 values
SELECT p.customer_id, SUM(amount) total, MIN(payment_date::date) first_order_date
FROM payment p
WHERE amount > 5
GROUP BY 1
HAVING
	EXTRACT(DOW FROM MIN(p.payment_date)::DATE) IN (0, 6)
	AND SUM(amount) > 100
ORDER BY 1;

SELECT a.*, EXTRACT(DOW FROM a.first_order_date) day_of_the_week
FROM (
	SELECT customer_id, SUM(amount) total, MIN(payment_date::date) first_order_date
FROM payment
WHERE amount > 5
GROUP BY 1
HAVING SUM(amount) > 100
ORDER BY 1
)a
WHERE EXTRACT(DOW FROM a.first_order_date) IN (0, 6);

-- course solution. returns 17 values
SELECT p.*, EXTRACT(DOW FROM p.payment_date), (
	SELECT SUM(amount)
	FROM payment p3
	WHERE p3.customer_id = p.customer_id
)
FROM payment p
WHERE p.payment_id = (
	SELECT MIN(p2.payment_id) 
	FROM payment p2
	WHERE p2.customer_id = p.customer_id
) AND p.amount > 5
AND EXTRACT(DOW FROM p.payment_date) IN (0, 6)
GROUP BY 1
HAVING (
	SELECT SUM(amount)
	FROM payment p3
	WHERE p3.customer_id = p.customer_id
) > 100;
``` 
one of the reasons of different results
     -> smaller payment_id in the table not equal to the small payment_date
```

-- REDO BASED ON payment_id not payment_date (returns 17 values)

-- STEP 1 CUSTOMER'S 1ST ORDER and TOTAL AMOUNT spent
SELECT p.customer_id, MIN(p.payment_id) first_payment_id, SUM(amount) as total_amount
FROM payment p
GROUP BY 1
ORDER BY 2;

-- STEP 2 Slice by total amount
SELECT p.customer_id, MIN(p.payment_id) first_payment_id, SUM(amount) as total_amount
FROM payment p
GROUP BY 1
HAVING SUM(amount) > 100
ORDER BY 2;

--STEP 3 USE JOINS AND CTE AND ADD DATE AND AMOUNT OF THE 1ST ORDER
WITH a AS (
	SELECT p.customer_id, MIN(p.payment_id) first_payment_id, SUM(amount) as total_amount
	FROM payment p
	GROUP BY 1
	HAVING SUM(amount) > 100
)
SELECT a.*, p.payment_date, p.amount
FROM a
JOIN payment p ON a.first_payment_id = p.payment_id;

--STEP 4. EXTRACT DAY OF THE WEEK
WITH a AS (
	SELECT p.customer_id, MIN(p.payment_id) first_payment_id, SUM(amount) as total_amount
	FROM payment p
	GROUP BY 1
	HAVING SUM(amount) > 100
)
SELECT a.*, p.payment_date, EXTRACT(DOW FROM p.payment_date) day_of_week, p.amount
FROM a
JOIN payment p ON a.first_payment_id = p.payment_id;

-- STEP 5 SLICE BY DOW AND AMOUNT
WITH a AS (
	SELECT p.customer_id, MIN(p.payment_id) first_payment_id, SUM(amount) as total_amount
	FROM payment p
	GROUP BY 1
	HAVING SUM(amount) > 100
)
SELECT a.*, p.payment_date, EXTRACT(DOW FROM p.payment_date) day_of_week, p.amount
FROM a
JOIN payment p ON a.first_payment_id = p.payment_id
WHERE amount > 5 AND EXTRACT(DOW FROM p.payment_date) IN (0, 6);