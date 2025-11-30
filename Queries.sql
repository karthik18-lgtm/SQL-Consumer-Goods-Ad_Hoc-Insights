

# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

SELECT 
	DISTINCT(market)
FROM dim_customer
WHERE customer = "Atliq Exclusive" 
	AND region = "APAC";

#2. What is the percentage of unique product increase in 2021 vs. 2020?

WITH y20 AS
	(SELECT 
		COUNT(DISTINCT(product_code)) AS unique_products_2020
	FROM fact_sales_monthly
	WHERE fiscal_year = 2020),
y21 AS 
	(SELECT 
		COUNT(DISTINCT(product_code)) AS unique_products_2021
	FROM fact_sales_monthly
	WHERE fiscal_year = 2021)
SELECT 
	unique_products_2020,
    unique_products_2021,
	ROUND(((y21.unique_products_2021 - y20.unique_products_2020)/unique_products_2020) *100,2) AS percentage_chg
FROM y20,y21;

#3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 

SELECT 
	segment,
	COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


#4. Follow-up: Which segment had the most increase in unique products in2021 vs 2020?

WITH y20 AS (
	SELECT 
		p.segment, COUNT(DISTINCT p.product_code) AS product_count_2020
	FROM dim_product p 
    JOIN fact_sales_monthly s ON p.product_code = s.product_code
	WHERE fiscal_year = 2020
	GROUP BY p.segment ),
y21 AS (
	SELECT
		p.segment, COUNT(DISTINCT p.product_code) AS product_count_2021
	FROM dim_product p
	JOIN fact_sales_monthly s ON p.product_code = s.product_code
	WHERE fiscal_year = 2021
	GROUP BY p.segment )
SELECT 
	y20.segment, product_count_2020, product_count_2021,
    (y21.product_count_2021 - y20.product_count_2020) AS difference
FROM y20 
JOIN y21 ON y20.segment = y21.segment
ORDER BY difference DESC;


#5. Get the products that have the highest and lowest manufacturing costs.

SELECT 
	p.product_code,
    p.product,
    m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
	ON p.product_code = m.product_code
WHERE m.manufacturing_cost IN 
(
SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost m
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost m
)
ORDER BY m.manufacturing_cost DESC;


#6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market

SELECT 
	c.customer,
    c.customer_code,
    ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer c
JOIN fact_pre_invoice_deductions pre
	ON c.customer_code = pre.customer_code
WHERE market = "India" AND fiscal_year = 2021
GROUP BY c.customer,c.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;


#7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.

SELECT 
	MONTHNAME(date) AS month,
	s.fiscal_year AS year,
	CONCAT(ROUND(SUM(sold_quantity*gross_price)/1000000,2), " M") AS gross_sales_amount
FROM fact_sales_monthly s
JOIN dim_customer c
	ON s.customer_code = c.customer_code
JOIN fact_gross_price g
	ON s.product_code = g.product_code
    AND s.fiscal_year = g.fiscal_year
WHERE customer = "Atliq Exclusive"
GROUP BY MONTH(s.date), MONTHNAME(date), s.fiscal_year
ORDER BY s.fiscal_year;


#8. In which quarter of 2020, got the maximum total_sold_quantity?

SELECT
	CASE
		WHEN month(date) IN (9,10,11) THEN "Q1"
		WHEN month(date) IN (12,1,2) THEN "Q2"
		WHEN month(date) IN (3,4,5) THEN "Q3"
		ELSE "Q4"
	END AS quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year =2020
GROUP BY quarters
ORDER BY total_sold_quantity DESC;


#9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?


WITH channels AS (
SELECT 
	c.channel,
    SUM(sold_quantity*gross_price) AS gross_sales
FROM fact_sales_monthly s
JOIN dim_customer c
	ON s.customer_code = c.customer_code
JOIN fact_gross_price g
	ON s.product_code = g.product_code
    AND s.fiscal_year = g.fiscal_year
WHERE s.fiscal_year = 2021
GROUP BY c.channel )

SELECT 
	channel,
	ROUND(gross_sales / 1000000, 2) AS gross_sales_mln,
    ROUND((gross_sales * 100) / SUM(gross_sales) OVER(), 2) AS percentage
FROM channels
ORDER BY percentage DESC;



#10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

WITH division AS (
	SELECT
		p.division,
        p.product_code,
        p.product,
		SUM(sold_quantity) AS total_sold_quantity
	FROM fact_sales_monthly s
	JOIN dim_product p
		ON s.product_code = p.product_code
	WHERE fiscal_year = 2021
	GROUP BY p.product, p.product_code, p.division),

product_rank AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_number
	FROM division )
    
SELECT *
FROM product_rank
WHERE rank_number <=3;

