--Q.2 Customers (customer_unique_id) whose total spend is above the average spend.
with customer_spent as (select c.customer_id, sum(op.payment_value) as spent
from customers c 
join orders o on o.customer_id = c.customer_id 
join order_payments op on op.order_id = o.order_id
group by c.customer_id )
select *
from customer_spent
where spent > (
	select AVG(spent)
	from customer_spent 
)
order by spent asc;

--Q.3 Sellers with no 1-star reviews at all — use NOT EXISTS.
with s_star as (select oi.seller_id  , t.review_score  
from order_items oi
join order_reviews t on t.order_id = oi.order_id 
)
select count(*)
from sellers sel 
where not exists (
	select 1
	from s_star s  
	where s.seller_id = sel.seller_id and s.review_score = 1
);

--Q.4 Monthly revenue for delivered orders.
select date_trunc('month', o.order_purchase_timestamp)::date as month, sum(op.payment_value)
from orders o
join order_payments op on op.order_id = o.order_id
where o.order_status = 'delivered'
group by month
order by month;

--Q.5 For each month, which product category earned the most delivered revenue?
with cat_month as (select p.product_category_name, date_trunc('month',o.order_purchase_timestamp) as month, sum(oi.price) cat_total
from order_items oi 
join products p on p.product_id = oi.product_id
join orders o on o.order_id = oi.order_id 
where o.order_status = 'delivered'
group by 1,2) 
select *
from cat_month c1
where cat_total = (
	select max(cat_total)
	from cat_month c2
	where c2.month = c1.month
)
order by month asc;

