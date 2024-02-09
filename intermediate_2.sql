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