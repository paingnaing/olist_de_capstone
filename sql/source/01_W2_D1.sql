--question 1 - How many customers are there in each state? Show the top 5 states.
select customer_state, count(*) as total
from customers c 
group by c.customer_state 
order by total desc
limit 5;

--question 2 - How many distinct real customers (customer_unique_id) are there?
select count( distinct customer_unique_id) as total_unique_customers
from customers;


--question 3 - Which payment_type is used most, and what is its total payment_value?
select op.payment_type , count(*) as total, SUM(op.payment_value )
from order_payments op 
group by op.payment_type 
order by total desc;


--question 4 - Count reviews for each score (1-5) and find the average score.
select 
	t.review_score, 
	count(*),
	round(((select AVG(t.review_score) from order_reviews t)), 2) as average_score
from order_reviews t
group by review_score
order by review_score asc;


--question 5 - Find seller states with more than 50 sellers.
select s.seller_state , count(*)
from sellers s 
group by s.seller_state
having count(*) > 50
order by count(*) desc


--question 6 - Calculate the average price and freight per item, rounded to 2 decimals.
select
	round((avg(price)),2) as avg_price,
	round((avg(oi.freight_value )),2) as avg_freight
from order_items oi 