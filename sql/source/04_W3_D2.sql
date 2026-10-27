--Q1. NULL audit: count NULLs in product_category_name and product_weight_g.
select count(*) filter (
		where p.product_category_name is null) as null_category,
		count(*) filter (
		where p.product_weight_g is null) as null_weight
from products p;

--Q2. For each month of purchase, what is the average delivery time, 
	--and how many orders (and what percentage) were delivered within 30 days of purchase?
with per_month_avg as(
select date_trunc('month',o.order_purchase_timestamp)::date as month,
avg(o.order_delivered_customer_date::date - o.order_purchase_timestamp::date) as avg_days_taken
from orders o
where o.order_status = 'delivered' and order_delivered_customer_date is not null
group by month
order by month asc
),
within_30_days as (
select date_trunc('month',o.order_purchase_timestamp)::date as month, count(*) as within_timeframe
from orders o
where o.order_status = 'delivered'
  and o.order_delivered_customer_date::date - o.order_purchase_timestamp::date <= 30
group by month
),
total_orders as (
select date_trunc('month', o.order_purchase_timestamp)::date as month, count(*) as total
from orders o
group by month
)
select t0.month, round((pma.avg_days_taken),2) as avg_delivery_days,coalesce(wd.within_timeframe,0) as within_30_days,
       t0.total as total_orders, round(coalesce(wd.within_timeframe,0) * 100.0 / nullif(t0.total,0), 2) as percentage
from  total_orders t0
left join per_month_avg pma on t0.month = pma.month
left join within_30_days wd on wd.month = t0.month
order by month asc;

--Q3. On which day of the week do customers place the most orders? 
	--Show each weekday’s name and number, and the total orders for that day, sorted from busiest to quietest.
-- (1. group orders with day extraction)
select to_char(o.order_purchase_timestamp, 'FMDay') as Day,extract(isodow from order_purchase_timestamp), count(*) Total_Orders
from orders o
group by Day, extract(isodow from o.order_purchase_timestamp)
order by Total_Orders desc
;

--Q4. What is the total revenue for each product category, shown with its English name? 
	--If a category has no English translation, show the original Portuguese name instead.
    --If the product has no category at all, show it as ‘unknown’.
select coalesce(ct.product_category_name_english, p.product_category_name, 'unknown'),
       sum(oi.price + oi.freight_value) as revenue
from order_items oi
join products p on p.product_id = oi.product_id
left join category_translation ct on ct.product_category_name = p.product_category_name
group by ct.product_category_name_english, p.product_category_name
order by revenue desc


--Q5. Group delivered orders by delivery speed:
--	Fast: 7 days or less from purchase to delivery.
--	Normal: 8 to 14 days.
--	Slow: 15 to 30 days.
--	Very slow: more than 30 days.
--How many orders fall into each group, and what percentage of the total is each?
with delivery_days as (
    select coalesce(o.order_delivered_customer_date::date, o.order_estimated_delivery_date::date) - o.order_purchase_timestamp::date as days_taken
    from orders o
    where o.order_status = 'delivered'
),
delivery_speed as (
    select case
        when days_taken <= 7 then 'Fast'
        when days_taken <= 14 then 'Normal'
        when days_taken <= 30 then 'Slow'
        Else 'Very slow'
        end as speed,
        count(*) as total_orders
    from delivery_days
    group by speed
    )
select speed, total_orders, round((total_orders*100.0/sum(total_orders) over()),2) as total_sum
from delivery_speed ds;