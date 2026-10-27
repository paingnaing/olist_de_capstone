--1. Revenue (SUM of price) by customer_state for delivered orders. Top 10 states.
select c.customer_state, sum(oi.price) as revenue 
from customers c
join orders o on o.customer_id = c.customer_id 
join order_items oi on oi.order_id = o.order_id 
where o.order_status = 'delivered'
group by c.customer_state 
order by revenue desc
limit 10;

--2. How many orders have no review at all? (anti-join)
select count(o.order_id)  
from orders o
where o.order_id not in (
	select t.order_id  from order_reviews t
);

--3. Top 10 product categories in English by items sold. Why LEFT JOIN to the translation?
select ct.product_category_name_english, count(oi.*) as count
from category_translation ct 
join products p on p.product_category_name = ct.product_category_name
join order_items oi on oi.product_id = p.product_id
group by ct.product_category_name_english 
order by count desc
limit 10;

--4. What share of order items were sold by a seller in the same state as the customer?
with total_order_items as (
	select count(*) as total
	from order_items oi
	join orders o on o.order_id = oi.order_id
	join customers c on c.customer_id = o.customer_id 
	join sellers s on s.seller_id = oi.seller_id
),
same_state as (
	select count(*) same_state
	from order_items oi
	join orders o on o.order_id = oi.order_id
	join customers c on c.customer_id = o.customer_id 
	join sellers s on s.seller_id = oi.seller_id
	where s.seller_state = c.customer_state 
)
select round((ss.same_state * 100.0 / toi.total), 2) as share
from total_order_items toi, same_state ss; 

--5. For 5 orders, show item revenue and payment total side by side — without fan-out.
with total_spent as (
	select oi.order_id, sum(price+oi.freight_value) as revenue 
	from order_items oi
	group by oi.order_id 
),
total_payment as (
	select op.order_id, sum(op.payment_value ) as payment
	from order_payments op  
	group by op.order_id 
)
select ts.order_id, ts.revenue, tp.payment
from total_spent ts 
join total_payment tp on tp.order_id = ts.order_id
order by ts.revenue desc 
limit 5;

--6. Find orders where payments differ from price + freight by more than 1.00.
with total_spent as (
	select oi.order_id, sum(price)+sum(oi.freight_value) as total_price
	from order_items oi
	group by oi.order_id 
),
total_payment as (
	select op.order_id, sum(op.payment_value ) as payment
	from order_payments op  
	group by op.order_id 
),
price_diff as (
	select ts.order_id, ts.total_price, tp.payment,
	case
		when tp.payment > ts.total_price + 1
		then tp.payment - ts.total_price 
	end as positive,
	case 
		when tp.payment < ts.total_price - 1
		then tp.payment - ts.total_price 
	end as negative
	from total_spent ts 
	join total_payment tp on tp.order_id = ts.order_id
)
select *
from price_diff
where positive is not null or negative is not null
order by negative asc, positive asc;


