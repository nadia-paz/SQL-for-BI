-- LAG function -> bakcward
-- LEAD -> forward

SELECT 	p.*, 
		LAG(p.payment_date) OVER(), 
		LAG(p.payment_id, 2) OVER(),
		LEAD(p.payment_id) OVER()
FROM payment p;

-- get INTERVAL
SELECT t.*, t.payment_date - t.prior_order AS time_between_orders
FROM (
	SELECT 	p.*, 
		LAG(p.payment_date) OVER() AS prior_order
	FROM payment p
) t;

-- same for every customer -> add PARTITION BY
-- also removes negative values in hrs difference
SELECT t.*, t.payment_date - t.prior_order AS time_between_orders,
	ROUND(EXTRACT(epoch FROM t.payment_date - t.prior_order) / 3600, 2) AS hours_since --interval to hrs
FROM (
	SELECT 	p.*, 
		LAG(p.payment_date) OVER(PARTITION BY p.customer_id) AS prior_order
	FROM payment p
) t;

-- ALTERNATIVE SYNTAX FOR WINDOW FUNCTIONS TO CALCULATE MOVING AVERAGE!!!
SELECT p.*, AVG(p.amount) OVER w
FROM payment p
WINDOW w AS (ORDER BY p.payment_id ROWS BETWEEN 0 PRECEDING AND 0 FOLLOWING);
-- 0 and 0 returns the same amount as amount, replacing 0 with values will calculate a moving avg

-- NTILE Window Function

-- top 10% of movies by dollar value rented

-- without window function
WITH movie_sales AS (
	SELECT f.film_id, f.title, SUM(p.amount) as sales
	FROM film f
	JOIN inventory i USING(film_id)
	JOIN rental r USING(inventory_id)
	JOIN payment p USING(rental_id)
	GROUP BY 1, 2
	ORDER BY 3 DESC
)
SELECT *
FROM movie_sales
LIMIT cast((SELECT COUNT(*) FROM movie_sales) * 0.1 AS INT);
-- returns 96 rows

-- with window function
WITH movie_sales AS (
	SELECT f.film_id, f.title, SUM(p.amount) as sales,
			NTILE(100) OVER(ORDER BY SUM(p.amount) DESC) AS percentile_rank,
			SUM(SUM(p.amount)) OVER() AS gloabal_sales
	FROM film f
	JOIN inventory i USING(film_id)
	JOIN rental r USING(inventory_id)
	JOIN payment p USING(rental_id)
	GROUP BY 1, 2
)
SELECT * FROM movie_sales WHERE percentile_rank <= 10;
-- returns 100 rows