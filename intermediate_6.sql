-- CPA. Customer Profitability Analysis

CREATE TABLE IF NOT EXISTS customer_sources (
   customer_id integer REFERENCES customer(customer_id) ON DELETE RESTRICT,
   traffic_source text,
   PRIMARY KEY(customer_id)
);

SELECT COUNT(*) FROM customer_sources;

COPY customer_sources
FROM '/var/lib/postgresql/dvd_db/customer_sources.csv'
DELIMITER ',';

CREATE TABLE IF NOT EXISTS source_spend_all (
	-- traffic source
   spend_source TEXT,
	-- money spent on the source
   spend INTEGER,
	-- visits from the source
   visits INTEGER
);

INSERT INTO source_spend_all(spend_source, spend, visits)
VALUES
	('google / cpc', 1606, 995),
	('bing / cpc', 133, 45),
	('direct / none', 0, 755),
	('google / organic', 750, 455),
	('moviereviews / display', 2886, 1200),
	('yelp / referral', 0, 99);
	
SELECT * FROM source_spend_all;
SELECT * FROM customer_sources;


WITH temp1 AS(
-- table that shows money spent and customers_acquired + life time value 
-- for each traffic source extended for each customer
	SELECT cs.customer_id, 
		cs.traffic_source, 
		sca.spend::money AS money_spent, 
		sca.visits AS shop_visits,
		(SELECT SUM(p.amount) FROM payment p WHERE cs.customer_id = p.customer_id) AS LTV
	FROM customer_sources cs
	JOIN source_spend_all sca ON cs.traffic_source = sca.spend_source
), temp2 AS (
	-- shows how many people that visited the shop became customers for every traffic source
	SELECT t1.traffic_source, 
			MAX(money_spent) AS money_spent, 
			MAX(shop_visits) AS shop_visits,
			COUNT(customer_id) AS customers_acquired,
			SUM(LTV)::money AS money_received
	FROM temp1 t1
	GROUP BY 1
)
SELECT t2.*, t2.money_spent / t2.customers_acquired AS CPA, t2.money_received
FROM temp2 t2
ORDER BY 5 DESC;
