-- Generate random numbers and CASE

WITH random_number AS (
	SELECT RANDOM() * 100 AS val
	FROM generate_series(1, 100)
)

SELECT rn.*,
	CASE 
	WHEN rn.val < 50 THEN 'below_50'
	WHEN rn.val > 50 THEN 'above_50'
	ELSE 'equal_50' END AS rand_outcome
FROM random_number AS rn;

-- repeat orders
WITH order_numbers AS (
	SELECT p.*,
		   ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date) AS rn
	FROM payment p
)
SELECT onbr.*, 
	CASE 
		WHEN onbr.rn = 1 THEN 'first_order'
		WHEN onbr.rn = 2 THEN 'second_order'
		WHEN onbr.rn = 3 THEN 'third_order'
		ELSE 'other_orders' END AS order_rank

FROM order_numbers onbr;
--
WITH order_numbers AS (
	SELECT p.*,
		   ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date) AS rn
	FROM payment p
)
SELECT onbr.*, 
	CASE 
		WHEN onbr.rn = 1 THEN 'first_order'
		WHEN onbr.rn > 1 THEN 'repeat_order'
		ELSE 'incorrect_value' END AS repeat_orders

FROM order_numbers onbr;

-- find customer's email, first order, most recent order, total amount spent,
-- preferred movie rating, list of ratings they rented from

-- PART I aggregations
WITH temp1 AS (
	SELECT p.*,
		   ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date ASC) AS first_order,
		   ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date DESC) AS last_order
	FROM payment p
), temp2 AS (
	SELECT * 
	FROM temp1 t1
	WHERE t1.first_order = 1 OR t1.last_order = 1
)
SELECT t2.customer_id, 
	MIN(t2.payment_date) AS first_order_date, 
	MAX(t2.payment_date) AS last_order_date,
	(
		SELECT SUM(p2.amount) FROM payment p2 WHERE p2.customer_id = t2.customer_id
	) AS total_spent_amount
FROM temp2 t2
GROUP BY 1
ORDER BY 1;

SELECT  p.customer_id, 
		MIN(p.payment_date) AS first_order_date, 
		MAX(p.payment_date) AS last_order_date,
		SUM(amount) AS total_spent_amount
FROM payment p
GROUP by 1
order by 1;

-- PART II. Prefered rating
SELECT t.customer_id, t.rating, COUNT(*) cnt,
	RANK() OVER(PARTITION BY t.customer_id ORDER BY COUNT(*) DESC) AS rnk
	-- ARRAY_AGG(t.rating) AS all_ratings -- didn't work correct
FROM (
	SELECT r.customer_id, r.inventory_id, i.film_id, f.rating
	FROM rental r
	JOIN inventory i USING(inventory_id)
	JOIN film f USING(film_id)
) t
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- PART III. LIST of all ratings rented
SELECT t.customer_id, ARRAY_AGG(t.rating)
FROM (
	SELECT r.customer_id, r.inventory_id, i.film_id, f.rating
	FROM rental r
	JOIN inventory i USING(inventory_id)
	JOIN film f USING(film_id)
) t
GROUP BY 1
ORDER BY 1;

-- PART IV. Put everything together
WITH agg_table AS (
	SELECT  p.customer_id, 
			MIN(p.payment_date) AS first_order_date, 
			MAX(p.payment_date) AS last_order_date,
			SUM(amount) AS total_spent_amount
	FROM payment p
	GROUP by 1
), temp AS (
	SELECT r.customer_id, r.inventory_id, i.film_id, f.rating
	FROM rental r
	JOIN inventory i USING(inventory_id)
	JOIN film f USING(film_id)
), preffered_rating AS (
	SELECT t.customer_id, t.rating, COUNT(*) cnt,
	-- MORE CORRECT is to use RANK but it leads to duplicates in the final table
	ROW_NUMBER() OVER(PARTITION BY t.customer_id ORDER BY COUNT(*) DESC) AS rnk
	FROM temp t
	GROUP BY 1, 2
), list_ratings AS (
	SELECT t.customer_id, ARRAY_AGG(t.rating) lst
	FROM temp t
	GROUP BY 1
)
SELECT c.customer_id, c.email,
	agt.first_order_date, agt.last_order_date, agt.total_spent_amount,
	pr.rating, lr.lst
FROM customer c
JOIN agg_table agt ON c.customer_id = agt.customer_id
JOIN preffered_rating pr ON c.customer_id=pr.customer_id AND pr.rnk = 1
JOIN list_ratings lr ON c.customer_id = lr.customer_id
ORDER BY 1


