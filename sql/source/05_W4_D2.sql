-- 1. For each seller state, find the 3 sellers who earned the most revenue.
-- find the total revenue for each seller
with seller_revenue as (select oi.seller_id seller_id, sum(oi.price) revenue
from order_items oi
group by seller_id),
-- (order them by state and revenue)
seller_ranking as(select sr.seller_id, s.seller_state, sr.revenue, row_number() over(partition by seller_state order by revenue desc) as ranking
from seller_revenue sr
join sellers s on s.seller_id = sr.seller_id)
-- (rank them)
select *
from seller_ranking
where ranking <= 3;

-- 2.For every customer, show the date of their first order and how many orders they placed in total.
-- (get customer first order date)
with first_order as(select c.customer_unique_id, min(o.order_purchase_timestamp::date) as first_order_date
from customers c
join orders o on o.customer_id = c.customer_id
group by c.customer_unique_id)
-- (group by customer_unique_id and get total number of orders)
select c.customer_unique_id, fo.first_order_date, count(*) total_orders
from orders o
join customers c on c.customer_id = o.customer_id
join first_order fo on fo.customer_unique_id = c.customer_unique_id
group by 1,2
order by total_orders desc
;

-- 3.For each seller, show how their revenue adds up over time, order by order. The running total starts again for each seller.
with order_revenue as (select oi.seller_id, o.order_id, o.order_purchase_timestamp::date as date, sum(price) as price
from orders o
join order_items oi on oi.order_id = o.order_id
group by 1,2,3)
select *, sum(price) over (partition by seller_id order by date, order_id rows between unbounded preceding and current row ) as revenue_over_time
from order_revenue
;

-- 4.What percentage of all money paid came from each payment type?
-- Get the grand total with SUM(…) OVER (), not a subquery. Round to 1 decimal.
with total_payment as (select op.payment_type payment_method, sum(op.payment_value) as total_sum
from order_payments op
where payment_value != 0
group by payment_method)
select *, round((tp.total_sum * 100.0/sum(total_sum) over ()), 1) as total_payment_percentage
from total_payment tp
;

-- 5.Find the order items whose price is higher than the average price in their product category.
-- Use AVG(price) OVER (PARTITION BY category).
-- Leave out products with no category.
with category_avg_price as(select order_id, p.product_category_name, oi.price, avg(price) over (partition by product_category_name) as Avg_price
from order_items oi
join products p on p.product_id = oi.product_id
where p.product_category_name is not null)
select *
from category_avg_price
where price > Avg_price
order by product_category_name, price;