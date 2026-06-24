SELECT
    branch,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM sales_transactions
GROUP BY branch
ORDER BY total_revenue DESC;



select category, round(sum(revenue), 2) as total_revenue
from sales_transactions
group by category
order by total_revenue desc;


SELECT
    meal_period,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM sales_transactions
GROUP BY meal_period
ORDER BY total_revenue DESC;


SELECT
    item_name,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM sales_transactions
GROUP BY item_name
ORDER BY total_revenue DESC
LIMIT 5;


SELECT
    item_name,
    sum(quantity) as total_quantity
FROM sales_transactions
GROUP BY item_name
ORDER BY total_quantity DESC
LIMIT 5;


select branch, 
	sum(revenue) as total_revenue,
	count(distinct order_id) as total_orders,
	round(sum(revenue):: numeric / 
	count(distinct order_id), 2) as AOV
from sales_transactions
group by branch
order by AOV desc;


SELECT 
    category, 
    ROUND(SUM(revenue), 2) AS total_revenue,
    -- Your percentage calculation column:
    ROUND((SUM(revenue):: numeric / (SELECT SUM(revenue) FROM sales_transactions)) * 100, 2) AS revenue_percentage
FROM sales_transactions
GROUP BY category
ORDER BY revenue_percentage DESC;


SELECT 
    category, 
    ROUND(SUM(revenue), 2) AS total_revenue,
    -- Your percentage calculation column:
    ROUND((SUM(revenue):: numeric /  SUM(SUM(revenue)) over() ) * 100, 2) AS revenue_percentage
FROM sales_transactions
GROUP BY category
ORDER BY revenue_percentage DESC;



select branch, 
	count(distinct order_id) as total_orders, 
	sum(revenue) as total_revenue,
	round(sum(revenue):: numeric/ 
	count(distinct order_id), 2) as AOV
from sales_transactions
group by branch
order by total_revenue desc;



select branch, count(distinct order_channel)
from sales_transactions
where branch = 'Birmingham Selfridges'
group by branch
limit 3;

SELECT
	branch,
	order_channel,
	COUNT (DISTINCT order_id) AS order_by_channel,
SUM (COUNT (DISTINCT order_id)) OVER(PARTITION BY branch) AS total_channel,
ROUND ((COUNT (DISTINCT order_id)::numeric / SUM (COUNT (DISTINCT order_id)) OVER(PARTITION BY branch))* 100, 2) AS channel_percentage
FROM sales_transactions
GROUP BY branch, order_channel
order by channel_percentage desc;



-- Show me the top 3 categories by revenue for each branch.

with Ranked_branches AS (
SELECT branch, category, sum(revenue) total_revenue,
row_number() OVER (PARTITION by branch order BY sum(revenue) DESC) as rank_branch
FROM sales_transactions
GROUP By branch, category
)
SELECT * from Ranked_branches where rank_branch <=3


WITH ranked_categories AS (
    SELECT
        branch,
        category,
        ROUND(SUM(revenue), 2) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY branch
            ORDER BY SUM(revenue) DESC
        ) AS category_rank
    FROM sales_transactions
    GROUP BY branch, category
)
SELECT
    branch,
    category,
    total_revenue,
    category_rank
FROM ranked_categories
WHERE category_rank <= 3
ORDER BY branch, category_rank;



-- query 1
--Top 3 Products by Revenue within each Branch

with top_product as(
select
branch,
item_name,
round(sum(revenue),2) as total_revenue,
row_number() over(PARTITION by branch ORDER BY sum(revenue) DESC) as product_rank
from sales_transactions
GROUP by branch, item_name
)
SELECT branch,
    item_name,
    total_revenue,
    product_rank 
	from top_product
where product_rank <= 3
ORDER BY branch, product_rank;



--query 2
-- Top 3 products by quantity within EACH branch

with top_product_by_quantity as(
select
branch,
item_name,
sum(quantity) as total_quantity,
row_number() over(PARTITION by branch ORDER BY sum(quantity) DESC) as quantity_rnk
from sales_transactions
GROUP by branch, item_name
)
SELECT branch,
    item_name,
    total_quantity,
    quantity_rnk  
	from top_product_by_quantity
where quantity_rnk <= 3
ORDER BY branch, quantity_rnk;


-- query 3
-- rank branches by revenue

with top_branch as (
select
branch,
round(sum(revenue),2) as total_revenue,
rank() over(order by sum(revenue) desc) as branch_rnk
FROM sales_transactions
GROUP by branch
)
SELECT branch, total_revenue, branch_rnk
from top_branch
ORDER by total_revenue desc;

-- dense_rank branches by revenue

with top_branch as (
select
branch,
round(sum(revenue),2) as total_revenue,
dense_rank() over(order by sum(revenue) desc) as branch_rnk
FROM sales_transactions
GROUP by branch
)
SELECT branch, total_revenue, branch_rnk
from top_branch
ORDER by total_revenue desc;



-- query 4
-- Monthly Revenue Running Total


with monthly_revenue_with_running_month as
(SELECT DATE_TRUNC('month', order_date)as month_number, sum(revenue) as monthly_revenue,
SUM(sum(revenue)) OVER (ORDER BY DATE_TRUNC('month', order_date)) as cumulative_revenue
from sales_transactions
GROUP by month_number
)
SELECT month_number, monthly_revenue,
cumulative_revenue  as running_month
from monthly_revenue_with_running_month
ORDER by month_number asc;


-- query 5
-- Show month-over-month revenue growth.


with monthly_revenue as (
	SELECT 
		DATE_TRUNC('month', order_date)as month_number, 
		sum(revenue) as monthly_revenue
	FROM sales_transactions
	GROUP by month_number
)
SELECT 
	month_number, 
	monthly_revenue,
LAG(monthly_revenue) OVER (ORDER BY month_number) as previous_month,
monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_number) as growth
from monthly_revenue
ORDER by month_number;


-- query 6
-- 

with highest_revenue_by_category as(
	select
		branch,
		category,
		sum(revenue) as total_revenue,
		row_number() over(PARTITION by branch ORDER BY sum(revenue) DESC) as rnk
		from sales_transactions
		GROUP by branch, category
)
SELECT *
from highest_revenue_by_category
where rnk = 1
ORDER BY total_revenue desc


-- query 7
-- Which category generates the highest percentage of revenue within each branch?

WITH category_share as (
	select
		branch,
		category,
		sum(revenue) as category_revenue,
		sum(sum(revenue)) over(PARTITION by branch) as branch_total_revenue
		from sales_transactions
		GROUP by branch, category
)
SELECT 
	branch,
	category,
	ROUND(category_revenue, 2) AS category_revenue,
    ROUND(branch_total_revenue, 2) AS branch_total_revenue,
	ROUND((category_revenue / branch_total_revenue) * 100, 2) AS revenue_percentage
FROM category_share
ORDER by branch, revenue_percentage desc;


-- query 8
-- Who are the Top 10 Customers by Revenue?
	
WITH item_share AS (
    SELECT
        category,
        item_name,
        SUM(revenue) AS item_revenue,
        SUM(SUM(revenue)) OVER(PARTITION BY category) AS category_total_revenue
    FROM sales_transactions
    GROUP BY category, item_name
)
SELECT
    category,
    item_name,
    ROUND(item_revenue, 2) AS item_revenue,
    ROUND(category_total_revenue, 2) AS category_total_revenue,
    ROUND((item_revenue / category_total_revenue) * 100, 2) AS revenue_percentage
FROM item_share
ORDER BY category, revenue_percentage DESC;


SELECT item_name, sum(revenue)
from sales_transactions
GROUP by item_name







	