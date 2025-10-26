# SQL-Data-Analytics-Project
A comprehensive collection of SQL scripts for data exploration, analytics, and reporting. These scripts cover various analyses such as database exploration, measures and metrics, time-based trends, cumulative analytics, segmentation, and more.


1. SQL Task. Analyze Sales Performance Over Time. Create change-over-time "Trends" to analyze how a measure evolves over time

SELECT 
YEAR(order_date) as order_year,
MONTH(order_date) as order_month,
SUM(sales_amount) as total_Sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)


SELECT 
FORMAT(order_date, 'yyyy-MMM') as order_date,
SUM(sales_amount) as total_Sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')


-- How many new customers were added each year
SELECT 
DATETRUNC(month, order_date) as order_date,
SUM(sales_amount) as total_Sales,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date)


2. Cumulative analysis - aggregate the data progressively over time - helps to understand whether our business is growing or declining
SQL TASK. Calculate the total sales per month and the running total of sales over time

-- Calculate the total sales per month
-- and the running total of sales over time
SELECT
order_date, 
total_sales,
-- window function
SUM(total_sales) OVER (partition by order_date ORDER BY order_date) AS running_total_sales
FROM 
(
SELECT
datetrunc(year, order_date) as order_date,
sum(sales_amount) as total_sales
FROM  gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY datetrunc(year, order_date)
) t 

SELECT
order_date, 
total_sales,
-- window function
SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER (ORDER BY order_date) as moving_average_price
FROM 
(
SELECT
datetrunc(year, order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
FROM  gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY datetrunc(year, order_date)
) t 


3. Performance Analysis - comparing the current value to a target value - helps measure success and compare performance

-- SQL TASK 3 
-- Analyze the yearly performance of products by comparing each product's sales 
-- to both its average sales performance and the previous year's sales

WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f 
LEFT JOIN gold.dim_products p  
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY
YEAR(f.order_date),
p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (partition BY product_name)  AS avg_sales,
current_sales - AVG(current_sales) OVER (partition by product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (partition by product_name) > 0 THEN 'Above Avg'
     WHEN current_sales - AVG(current_sales) OVER (partition by product_name) < 0 THEN 'Below Avg'
     ELSE 'Avg'
END avg_change,
-- Year-over-year Analysis
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
     WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
     ELSE 'No change'
END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year









4. Part-to-whole Analysis - analyze how an individual part is performing compared to the overall, allowing us to understand which category has the greatest impact on the business - [measure / total measure]* 100 by [dimension]

-- SQL Task. Which categories contribute the most to overall sales?

WITH category_sales as (
select 
category,
sum(sales_amount) AS total_sales
from gold.fact_sales f
left join gold.dim_products p 
ON p.product_key = f.product_key
GROUP BY category)

SELECT
category, 
total_sales,
sum(total_sales) over () AS overall_sales,
CONCAT(ROUND((cast (total_sales as float) / SUM(total_sales) OVER () )*100, 2), '%')  AS percentage_of_total
from category_sales
ORDER BY total_sales DESC


5. Data Segmentations - helps understand the correlation between two measures
[Measure] by [Measure] - total customers by age for example

-- SQL TASK. Group customers into three segments based on their spending behavior
-- VIP: at least 12 months of history and spending more tham 5 000 E
-- Regular: at least 12 month of history but spending 5000 or less
-- New: lifespan less than 12 months
-- Find the total number of customers by each group

with customer_spending AS(
select 
c.customer_key,
SUM(f.sales_amount) as total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF (month, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales f 
left join gold.dim_customers c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT 
customer_key, 
total_spending,
lifespan,
case when lifespan >= 12 and total_spending > 5000 then 'VIP'
    when lifespan >= 12 and total_spending <= 5000 then 'Regular'
    else 'New customer'
end cusomer_segment
FROM customer_spending

2 variant 
with customer_spending AS(
select 
c.customer_key,
SUM(f.sales_amount) as total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF (month, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales f 
left join gold.dim_customers c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key)

SELECT 
customer_segment,
COUNT(customer_key) as total_customers
FROM (
    select
    customer_key,    
    case when lifespan >= 12 and total_spending > 5000 then 'VIP'
        when lifespan >= 12 and total_spending <= 5000 then 'Regular'
        else 'New customer'
    end customer_segment
    FROM customer_spending ) t 
GROUP BY customer_segment
ORDER BY total_customers DESC
   



