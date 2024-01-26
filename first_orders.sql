SELECT p2.customer_id, min(p2.payment_date) as fo_date
FROM payment p2 
GROUP BY 1;

-- FINDING all data about a customer's first order
-- Should have 1 row for each customer
-- the min is determined by the payment_date

-- 56ms
SELECT p.* FROM payment p
	JOIN (
	  SELECT p2.customer_id, min(p2.payment_date) as first_order
	  FROM payment p2 
	  GROUP BY 1 
	) a ON a.first_order = p.payment_date
ORDER BY 2;

-- row_number
-- can you get a list of orders by staff member, in reverse order?
-- get customer's most recent orders?

SELECT p.*, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date)
FROM payment p;

-- get first orders for each customer
-- 58ms
SELECT * FROM (
	SELECT p.*, ROW_NUMBER() 
				OVER(PARTITION BY customer_id ORDER BY payment_date) as rn
	FROM payment p
    ) a
WHERE a.rn = 1;

```
self join runs a bit faster then window function, 
CTE is the slowest (explain plan is the same as window functions)
```

-- rewrite with CTE
-- 75ms
WITH first_orders AS (
    SELECT * FROM (
	SELECT p.*, ROW_NUMBER() 
				OVER(PARTITION BY customer_id ORDER BY payment_date) as rn
	FROM payment p
    ) a
WHERE a.rn = 1
)
SELECT * FROM first_orders;