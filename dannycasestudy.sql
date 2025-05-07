create database casestudy;
use casestudy;

#1. What is the total amount each customer spent at the restaurant?
select customer_id , sum(price) as Total_spent 
from sales join menu using(product_id)
group by customer_id;


#2. How many days has each customer visited the restaurant? 

select customer_id ,
count(distinct  order_date)count from sales 
group by customer_id;

#3. What was the first item from the menu purchased by each customer?
select * from
(select customer_id,order_date,product_name, row_number() over(partition by customer_id) cnt 
from sales  s join menu m using(product_id))
as t where cnt = 1;

#4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id) cn from sales s join menu m using(product_id)
group by m.product_name order by cn desc limit 1;

select * from (
select product_name,count(*) as NO_OF_ITEMS,
rank() over(order by count(product_name) desc) as rn
from sales s
inner join menu m using(product_id)
group by product_name) as t where rn =1;

#5. Which item was the most popular for each customer?
select * from 
(select customer_id, product_name,count(*) as NOOrder, 
dense_rank() over(partition by customer_id order by count(*) desc) cn
from sales s join menu m using(product_id) group by customer_id,product_name)as t where cn =1;

#6. Which item was purchased first by the customer after they became a member?
select * from
(select s.customer_id,order_date, product_name,
row_number() over(partition by s.customer_id order by order_date) rn
from sales s join menu m using(product_id) 
join members mb on s.customer_id= mb.customer_id and s.order_date>mb.join_date )
as t where rn =1;

with f_purchased as 
(select s.customer_id,order_date, product_name,
row_number() over(partition by s.customer_id order by order_date) rn
from sales s join menu m using(product_id) 
join members mb on s.customer_id= mb.customer_id and s.order_date>mb.join_date)
 select * from f_purchased where rn =1;
 
 #7. Which item was purchased just before the customer became a member?
 with before_purchased as 
(select s.customer_id,order_date, product_name,
row_number() over(partition by s.customer_id order by order_date desc) rn
from sales s join menu m using(product_id) 
join members mb on s.customer_id= mb.customer_id and s.order_date<=mb.join_date)
 select * from before_purchased where rn =1;
 
 #8. What is the total items and amount spent for each member before they became a member?
 select s.customer_id,count(s.product_id) Items,sum(m.price) Total_Amount from sales s join members mb 
 on s.customer_id=mb.customer_id and s.order_date<mb.join_date
 join menu m using(product_id) group by s.customer_id order by customer_id;

#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier -
# how many points would each customer have?
 select customer_id, sum(case when product_name ='Sushi' then price*20 else price*10 end) Total_points
 from sales s join menu m using(product_id) group by customer_id;
 
 #10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
 #not just sushi - how many points do customer A and B have at the end of January?*/
 select s.customer_id,sum(case when order_date between mb.join_date and date_add(join_date,interval 7 day)
then price * 20 when product_name= 'sushi' then price * 20 else price * 10 end ) as Total_Points
from sales s inner join members mb using(customer_id) inner join menu m using(product_id)
where order_date <= '2021-01-31'
group by s.customer_id order by customer_id;
 
 
 
select * from sales;
select * from menu;
select * from members;