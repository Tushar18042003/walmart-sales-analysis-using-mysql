-- task 1
with monthly_sales as (
select Branch, DATE_FORMAT(D_ate, '%Y-%m') as month, SUM(Total) as monthly_total
from salesdt
group by Branch, DATE_FORMAT(D_ate, '%Y-%m')
),
growth_calc as (
select a.Branch, a.month, a.monthly_total,
lag(a.monthly_total) over (partition by a.Branch order by a.month) as prev_month_total
from monthly_sales a
)
select Branch, month, monthly_total, prev_month_total,
ROUND(((monthly_total - prev_month_total) / prev_month_total) * 100, 2) as growth_rate_percent
from growth_calc
where prev_month_total is not null;


-- task 2
with profit_summary as (
select Branch, Product_line, SUM(gross_income) as total_income,
SUM(cogs) AS total_cogs, SUM(total) - SUM(cogs) AS profit
FROM salesdt
group by Branch, Product_line
),
ranked_profit as (
select *,rank() over (partition by Branch order by profit desc) as rank_in_branch
from profit_summary
)
select Branch, Product_line, total_income, total_cogs, profit
from ranked_profit
where rank_in_branch = 1;


-- task 3
with customer_purchase as (
select Customer_ID, sum(total) as total_spent, sum(gross_income) as total_profit
from salesdt
group by Customer_ID
order by total_spent
),
customer_tier as(
select Customer_ID, total_spent, total_profit,
case
when total_spent < 20000 then "LOW"
when total_spent <= 25000 then "MEDIUM"
else "HIGH"
end as tier
from customer_purchase
)
select * from customer_tier;


-- task 4
with stats as (
select Product_line, avg(Total) as avg_total
from salesdt
group by Product_line
),
anomalies as (
select Invoice_ID, s.Product_line, Branch, Total,  st.avg_total,
case 
-- can be changed to desired range like 10%, 20%, 25%, 30%
when Total > avg_total * 1.3 then 'High Anomaly' 
WHEN Total < avg_total * 0.5 then'Low Anomaly'
else null
end as anomaly_flag
from salesdt s
join stats st on s.Product_line = st.Product_line
)
select *
from anomalies
where anomaly_flag is not null;


-- task 5
with payment_counts as (
select City, Payment, COUNT(*) as payment_count
from salesdt
group by City, Payment
),
ranked_methods as (
select *,rank() over (partition by City order by payment_count desc) as payment_rank
from payment_counts
)
select City,  Payment as most_popular_payment_method, payment_count
from ranked_methods
where payment_rank = 1;


-- task 6
select DATE_FORMAT(D_ate, '%M') as month_name,
Gender, round(sum(Total), 2) as monthly_sales
from salesdt
group by DATE_FORMAT(D_ate, '%Y-%m'),
DATE_FORMAT(D_ate, '%M'),Gender
order by DATE_FORMAT(D_ate, '%Y-%m'),Gender;

-- task 7
with product_preference as (
select Customer_type, Product_line, sum(Total) as total_sales
from salesdt
group by Customer_type, Product_line
),
ranked_products as (
select *,
rank() over (partition by Customer_type order by total_sales desc) as rank_in_type
from product_preference
)
select Customer_type, Product_line as top_product_line,
round(total_sales, 2) as total_sales
from ranked_products
where rank_in_type = 1;

-- task 8
with ranked_sales as (
select Customer_ID, D_ate,
row_number() over (partition by Customer_ID order by D_ate) as rn
from salesdt
),
paired_dates as(
select curr.Customer_ID, curr.D_ate as _current_date,
nxt.D_ate as next_date,
DATEDIFF(nxt.D_ate, curr.D_ate) as days_diff
from ranked_sales curr
join ranked_sales nxt
on curr.Customer_ID = nxt.Customer_ID and curr.rn + 1 = nxt.rn
)
select * 
from paired_dates
where days_diff between 1 and 30;

-- task 9
select Customer_ID,
round(sum(Total), 2) as total_spent,
round(sum(gross_income), 2) AS total_profit
from salesdt
group by Customer_ID
order by total_spent desc
limit 5;

-- task 10
select 
dayname(D_ate) as day_of_week,
round(sum(Total), 2) as total_sales
from salesdt
group by day_of_week
order by total_sales desc;

