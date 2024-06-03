-- Gross revenue per actor, per film

WITH temp_a AS (
	-- calculate rental amount per movie (for all actors from that movie)
	SELECT p.amount, 
		r.inventory_id, 
		f.film_id, 	
		a.actor_id,
		a.first_name || ' ' || a.last_name as actor_name
		
	FROM payment p 
	 JOIN rental r ON r.rental_id = p.rental_id
	 JOIN inventory i ON i.inventory_id = r.inventory_id
	 JOIN film f ON f.film_id = i.film_id
	 JOIN film_actor fa ON fa.film_id = f.film_id
	 JOIN actor a ON fa.actor_id = a.actor_id
), temp_b AS (
	-- total sales per movie
	SELECT  f.film_id, SUM(p.amount) as total_sales
	FROM payment p 
	 JOIN rental r ON r.rental_id = p.rental_id
	 JOIN inventory i ON i.inventory_id = r.inventory_id
	 JOIN film f ON f.film_id = i.film_id
	 GROUP BY 1 ORDER BY 2 DESC
), temp_c AS (
	
	SELECT t1.film_id, t2.total_sales, 
	-- array of actors played in movie
	ARRAY_AGG(DISTINCT t1.actor_id) actors_list, 
	-- number of actors played in movie
	ARRAY_LENGTH(ARRAY_AGG(DISTINCT t1.actor_id), 1) as number_of_actors
	FROM temp_a t1 JOIN temp_b t2 ON t2.film_id = t1.film_id
	GROUP BY 1,2
), temp_d AS (
	-- gross revenue per actor per film
	SELECT film_id, actors_list, ROUND(total_sales / number_of_actors, 2) AS gross_revenue_per_actor
	FROM temp_c
)
-- calculate the gross revenue per actor in each rental movie
SELECT t1.actor_id, t1.actor_name, SUM(t4.gross_revenue_per_actor)
FROM temp_a t1
JOIN temp_d t4 ON t1.film_id = t4.film_id
GROUP BY 1, 2 
ORDER BY 3 DESC