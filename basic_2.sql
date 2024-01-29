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