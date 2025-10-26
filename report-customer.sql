-- SQL TASK. Customer Report.
CREATE VIEW gold.report_customers AS 
With base_query AS (
    -- 1) Base Query: Retrieves core columns from tables
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) as customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) as age
FROM gold.fact_sales f 
LEFT JOIN gold.dim_customers c 
ON c.customer_key = f.customer_key
where order_date is not NULL ),

customer_aggregation as (
--2) Customer Aggregations: Summarizes key metrics at the customer level
SELECT 
customer_key,
customer_number,
customer_name,
age,
Count(distinct order_number) as total_orders,
SUM (sales_amount) as total_sales,
sum (quantity) as total_quantity, 
count(distinct product_key) as total_products,
max(order_date) as last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) as lifespan
FROM base_query
group by 
    customer_key,
    customer_number,
    customer_name,
    age
)
select 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 then 'Under 20'
    when age between 20 and 29 then '20-29'
    when age between 30 and 39 then '30-39'
    when age between 40 and 49 then '40-49'
ELSE '50 and above'
END AS age_group,

case when lifespan >= 12 and total_sales > 5000 then 'VIP'
        when lifespan >= 12 and total_sales <= 5000 then 'Regular'
        else 'New customer'
end customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency, 
total_orders,
total_sales,
total_quantity, 
total_products,
lifespan,
-- Compuate average order value (AVO)
Case when total_sales = 0 then 0
    else total_sales / total_orders
END AS avg_order_value,

-- Compuate average monthly spend 
case when lifespan = 0 then total_sales
    else  total_sales / lifespan
END AS avg_monthly_spend
from customer_aggregation 

Select 
age_group,
Count(customer_number) as total_customers,
SUM(total_sales) as total_sales
from gold.report_customers
group by age_group
