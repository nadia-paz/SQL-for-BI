-- 1st order ratings popularity and sales
WITH first_order AS (
	SELECT * FROM (
		SELECT p.*, 
		ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date) AS order_number
		FROM payment p
	)t WHERE t.order_number = 1
)
-- JOINS
-- Rental -> Inventory -> Film
SELECT x.rating, SUM(x.amount), COUNT(*) FROM (
		SELECT fo.*, r.*, i.*, f.*
		FROM first_order fo
		JOIN rental r USING(rental_id)
		JOIN inventory i USING(inventory_id)
		JOIN film f USING(film_id)
)x
GROUP BY 1;

--- CREATE A denormalized TEMP TABLE for first order information
SELECT *
INTO temp_table
FROM (
WITH first_order AS (
	SELECT * FROM (
		SELECT p.*, 
		ROW_NUMBER() OVER(PARTITION BY p.customer_id ORDER BY p.payment_date) AS order_number
		FROM payment p
	)t WHERE t.order_number = 1
)
SELECT  fo.customer_id,
		fo.payment_id,
		fo.amount, 
		fo.payment_date,
		r.rental_id,
		r.rental_date,
		r.return_date,
		r.last_update as last_rental_update,
		i.inventory_id,
		f.*
FROM first_order fo
JOIN rental r USING(rental_id)
JOIN inventory i USING(inventory_id)
JOIN film f USING(film_id)	
)t;

-- Customer's lifetime's spent for rating
SELECT x.rating, AVG(x.lifetime_spent) FROM (
	SELECT t.customer_id, t.rating, SUM(t.amount) as fo_amount, COUNT(*), 
			(SELECT SUM(p.amount) FROM payment p WHERE p.customer_id = t.customer_id) as lifetime_spent
	FROM temp_table t
	GROUP BY 1, 2
)x GROUP BY 1;