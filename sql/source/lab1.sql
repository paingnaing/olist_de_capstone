--question 1 - How many customers are there in each state? Show the top 5 states.
select customer_state, count(*) as total
from customers c 
group by c.customer_state 
order by total desc
limit 5;

--question 2 - How many distinct real customers (customer_unique_id) are there?
select distinct count(customer_unique_id) as total_unique_customers
from customers

--question 3 - Which payment_type is used most, and what is its total payment_value?
select op.payment_type , count(*) as total, SUM(op.payment_value )
from order_payments op 
group by op.payment_type 
order by total desc
