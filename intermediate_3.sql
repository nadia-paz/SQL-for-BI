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

-- find top 5 actors by gross revenue
-- find all movies where those actors appeared
-- what % of all customers rents those movies
-- find all customers that rented those movies
With temp AS (
	SELECT  a.actor_id,
			a.first_name || ' ' || a.last_name as actors,
			p.amount, 
			r.inventory_id, 
			f.film_id
	FROM payment p 
	 JOIN rental r ON r.rental_id = p.rental_id
	 JOIN inventory i ON i.inventory_id = r.inventory_id
	 JOIN film f ON f.film_id = i.film_id
	 JOIN film_actor fa ON fa.film_id = f.film_id
	 JOIN actor a ON fa.actor_id = a.actor_id
),
top_5 AS (
	SELECT t.actor_id, t.actors, SUM(t.amount)
	FROM temp t
	GROUP BY 1, 2
	ORDER BY 3 DESC
	LIMIT 5
), top_movies_and_actors AS (
	-- returns 198 rows, some of top rating actors appeared in same movies
	SELECT fa.film_id, f.title, top_5.actor_id, top_5.actors
	FROM film_actor fa

	JOIN film f ON fa.film_id = f.film_id
	JOIN top_5 ON fa.actor_id = top_5.actor_id
	WHERE fa.actor_id IN (SELECT top_5.actor_id FROM top_5)
), top_movies AS (
	-- returns 183 rows, unique top movies
	SELECT DISTINCT(fa.film_id)
	FROM film_actor fa
	WHERE fa.actor_id IN (SELECT top_5.actor_id FROM top_5)
),
-- find customers that rented those movies
cust_a AS (
	SELECT i.film_id, c.customer_id, c.first_name || ' ' || c.last_name as customer_name
	FROM inventory i
	JOIN rental r ON r.inventory_id = i.inventory_id
	JOIN customer c ON r.customer_id = c.customer_id
	WHERE i.film_id IN (SELECT tm.film_id FROM top_movies tm)
), cust_b AS (
SELECT p.amount, p.customer_id, r.inventory_id, f.film_id
	FROM payment p 
	 JOIN rental r ON r.rental_id = p.rental_id
	 JOIN inventory i ON i.inventory_id = r.inventory_id
	 JOIN film f ON f.film_id = i.film_id
	WHERE f.film_id IN (SELECT tm.film_id FROM top_movies tm)
)
SELECT COUNT(DISTINCT(cust_b.customer_id)) FROM cust_b;

-- 591 out of 599 rented movies with top-5 actors playing in them
