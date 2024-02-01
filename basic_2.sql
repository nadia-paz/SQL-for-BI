-- using subqueries

-- subquery instead of when case
SELECT val, COUNT(*) FROM (
	SELECT 'above' AS val, f.replacement_cost 
	FROM film f 
	WHERE replacement_cost > (SELECT AVG(replacement_cost) FROM film)
		UNION
	SELECT 'below_equal' AS val, f.replacement_cost 
	FROM film f 
	WHERE replacement_cost <= (SELECT AVG(replacement_cost) FROM film)
)t
GROUP BY 1;

-- get all the info from the original table when need to group by using JOIN

SELECT p.*
FROM payment p JOIN (
	SELECT p2.customer_id, MIN(payment_date) as first_order 
	FROM payment p2 
	GROUP BY 1
) t ON p.customer_id = t.customer_id AND p.payment_date = t.first_order;

-- get customer's total amount and how much customers spent on their  month/year of their 1st order

WITH t AS (
    -- pull total amount spent, month and year of first order
    --group by customer id
	SELECT p.customer_id, SUM(p.amount) total_spent, 
	(
		SELECT EXTRACT(MONTH FROM MIN(payment_date)) AS first_month
		FROM payment p2
		WHERE p2.customer_id = p.customer_id
	),
	(
		SELECT EXTRACT(YEAR FROM MIN(payment_date)) AS first_year
		FROM payment p3
		WHERE p3.customer_id = p.customer_id
	) 
	FROM payment p
	GROUP BY 1
)
-- add the amount spent in the first month with the rental company
SELECT t.customer_id, t.total_spent,
(
	SELECT SUM(p4.amount)
	FROM payment p4
	WHERE p4.customer_id = t.customer_id AND
		EXTRACT(MONTH FROM p4.payment_date) = t.first_month AND
		EXTRACT(YEAR FROM p4.payment_date) = t.first_year
) amount_first_month
FROM t;

-- select top renting movies in every rating class

WITH ranked_rental AS (
	SELECT f.film_id, 
	   f.title, 
	   f.rating, 
	   SUM(p.amount) total_rental_amount,
	   ROW_NUMBER() OVER(PARTITION BY f.rating ORDER BY SUM(p.amount) DESC)
	FROM film f
	JOIN inventory i USING(film_id)
	JOIN rental r USING(inventory_id)
	JOIN payment p USING(rental_id)
	GROUP BY 1, 2, 3
	ORDER BY  total_rental_amount DESC
)
SELECT * 
FROM ranked_rental
WHERE row_number = 1;

-- DATE AND TIME

SELECT 
		p.payment_date::date,
		-- CAST(p.payment_date AS DATE) same_as_above,
		to_char(p.payment_date::date, 'DD/MM/YY'),
		to_char(p.payment_date::date, 'DDth Month, YYYY'),
		EXTRACT(DOW FROM p.payment_date) day_of_week,
		age(p.payment_date::date),
		CAST(p.payment_date + INTERVAL '10 days' AS DATE) as ten_days_after,
		COUNT(*)
FROM payment p
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY 1;

-- Last name of ppl starts with a vowel AEIOU
-- regex starts with -> '^[AEIOUaeiou]'

SELECT c.last_name, substring(c.last_name, '^[AEIOUaeiou]') AS first_letter
FROM customer c;

SELECT first_letter_class, COUNT(*) 
FROM(
	SELECT c.last_name, 
		substring(c.last_name, '^[AEIOUaeiou]') AS first_letter,
		CASE  
			WHEN substring(c.last_name, '^[AEIOUaeiou]') IS NOT NULL THEN 'consonant'
			ELSE 'vowel' END first_letter_class
	FROM customer c
) t
GROUP BY 1;