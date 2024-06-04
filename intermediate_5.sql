-- generate interval series
SELECT d, d + INTERVAL '1 week' AS week_from_now
FROM generate_series('2024-05-01', current_date, INTERVAL '1 day') AS d;

SELECT * FROM (
	-- look for the 1st order for each customer
	-- 599 customers = 599 rows
	SELECT p.customer_id, 
		p.payment_date, 
		p.amount,
		ROW_NUMBER() OVER(
		PARTITION BY p.customer_id ORDER BY p.payment_date
		)
	FROM payment p
) AS a WHERE a.row_number = 1;

-- use the table above as a starting point to calculate how much customers spent:
-- on their first week
-- first 2 weeks
-- life time value

WITH temp1 AS (
	SELECT * FROM (
		-- look for the 1st order for each customer
		-- 599 customers = 599 rows
		SELECT p.customer_id, 
			p.payment_date, 
			p.amount AS first_order_amount,
			ROW_NUMBER() OVER(
			PARTITION BY p.customer_id ORDER BY p.payment_date
			)
		FROM payment p
	) AS a WHERE a.row_number = 1
)
SELECT temp1.*, (
	-- sales during the 1st week of being a customer
	SELECT SUM(p2.amount)
	FROM payment p2
	WHERE p2.customer_id = temp1.customer_id
		AND p2.payment_date 
			BETWEEN temp1.payment_date AND temp1.payment_date + INTERVAL '1 week'
) AS first_week_sales,(
	-- sales during the 1st two weeks of being a customer
	SELECT SUM(p2.amount)
	FROM payment p2
	WHERE p2.customer_id = temp1.customer_id
		AND p2.payment_date 
			BETWEEN temp1.payment_date AND temp1.payment_date + INTERVAL '2 weeks'
) AS first_2weeks_sales, (
	-- life time value
	SELECT SUM(p2.amount)
	FROM payment p2
	WHERE p2.customer_id = temp1.customer_id
) AS LTV

FROM temp1
ORDER BY 7 DESC;