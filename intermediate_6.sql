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
), temp3 AS (
	SELECT t2.traffic_source, 
			t2.customers_acquired,
			t2.money_spent,
			t2.money_received,
			t2.money_received - t2.money_spent AS total_profit,
			t2.money_spent / t2.customers_acquired AS cost_of_customer,
			(t2.money_received - t2.money_spent) / t2.customers_acquired AS profit_per_customer
	FROM temp2 t2
)
SELECT t3.*, t3.profit_per_customer - t3.cost_of_customer AS CPA
FROM temp3 t3
ORDER BY CPA;

-- RESULTS
/*
"traffic_source"	"customers_acquired"	"money_spent"	"money_received"	"total_profit"	"cost_of_customer"	"profit_per_customer"	"cpa"
"moviereviews / display"	54	            "$2,886.00"	    "$5,609.51"	        "$2,723.51"	    "$53.44"	        "$50.43"	            "-$3.01"
"google / organic"	 95	                    "$750.00"	    "$9,514.36"	        "$8,764.36"	    "$7.89"	            "$92.25"	            "$84.36"
"google / cpc"	    189	                    "$1,606.00"	    "$19,347.94"	    "$17,741.94"	"$8.49"	            "$93.87"	            "$85.38"
"bing / cpc"	    27	                    "$133.00"	    "$2,824.24"	        "$2,691.24"	    "$4.92"	            "$99.67"	            "$94.75"
"direct / none"	    151	                    "$0.00"	        "$15,328.79"	    "$15,328.79"	"$0.00"	            "$101.51"	            "$101.51"
"yelp / referral"	83	                    "$0.00"	        "$8,687.20"	        "$8,687.20"	    "$0.00"	            "$104.66"	            "$104.66"
*/