--1) What is the total amount each customer spent at the restaurant?

select 
  s.customer_id,
  sum(m.price) as total_spent_by_customer 
from 
  sales s 
inner join menu m on s.product_id = m.product_id
group by 
  s.customer_id;


--2) How many days has each customer visited the restaurant?

select 
  s.customer_id, 
  count(distinct order_date) as customer_spent 
from 
  sales s 
group by 
  s.customer_id
  

--3) What was the first item from the menu purchased by each customer?

with ordered_sales_rank as (
select 
  s.customer_id as customer_id, 
  s.order_date as order_date, 
  m.product_name as product_name, 
  dense_rank() over(partition by s.customer_id order by s.order_date) rn 
from 
  sales s 
inner join menu m on s.product_id = m.product_id)
select 
  customer_id, 
  product_name 
from 
  ordered_sales_rank
where rn = 1
group by 
  customer_id, 
  product_name;
  

--4) What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 
  m.product_name as product_name, 
  count(1) as no_of_products_sold 
from 
  sales s
inner join menu m on s.product_id = m.product_id
group by 
  m.product_name
order by 
  count(1) desc;


--5) Which item was the most popular for each customer?

with fav_item_cte as (
select 
  s.customer_id as customer_id, 
  m.product_name as product_name, 
  count(1) as no_of_products_purchased, 
  dense_rank() over(partition by s.customer_id order by count(1) desc) as highest_purchased_rn 
from 
  sales s
inner join menu m on s.product_id = m.product_id
group by s.customer_id, m.product_name)
select 
  customer_id, 
  product_name, 
  no_of_products_purchased as fav_product 
from 
  fav_item_cte
where highest_purchased_rn = 1;


--6) Which item was purchased first by the customer after they became a member?

with first_purchase_cte as (
select 
    s.customer_id as customer_id,
    s.order_date as order_date,
    mem.join_date as join_date,
    m.product_name as product_name,
    dense_rank() over(partition by s.customer_id order by s.order_date) as purchase_rank
from
    sales s
inner join members as mem on s.customer_id = mem.customer_id
inner join menu as m on s.product_id = m.product_id
where order_date >= join_date)
select 
    customer_id, 
    product_name,
    order_date
from first_purchase_cte
where purchase_rank = 1;


--7) Which item was purchased just before the customer became a member?

with first_purchase_cte as (
select 
    s.customer_id as customer_id,
    s.product_id as product_id,
    s.order_date as order_date,
    mem.join_date as join_date,
    dense_rank() over(partition by s.customer_id order by s.order_date desc) as purchase_rank
from
    sales s
inner join members as mem on s.customer_id = mem.customer_id

where order_date < join_date)
select 
    customer_id, 
    m.product_name as product_name,
    order_date
from first_purchase_cte fpc
inner join menu as m on fpc.product_id = m.product_id
where purchase_rank = 1;


--8) What is the total items and amount spent for each member before they became a member?

select 
    s.customer_id as customer_id, 
    sum(m.price) as amount_spent, 
    count(distinct m.product_id) as total_items
from 
    sales s
inner join members as mem on s.customer_id = mem.customer_id
inner join menu as m on s.product_id = m.product_id
where s.order_date < mem.join_date
group by 
    s.customer_id;
    

--9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 
    s.customer_id as customer_id, 
    sum(case 
        when m.product_name = 'sushi' then price*2*10
        else price*10
    end) as total_points
from
  sales s
inner join menu as m on s.product_id = m.product_id
group by 
    s.customer_id;
    

/*10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
      not just sushi - how many points do customer A and B have at the end of January?*/
 
 select 
    s.customer_id as customer_id,
    sum(case 
            when datediff(day, mem.join_date, s.order_date) <= 6 then price*2*10
            when m.product_name = 'sushi' then price*2*10
            else price*10 
        end) as total_points    
from
    sales s
inner join members as mem on s.customer_id = mem.customer_id
inner join menu as m on s.product_id = m.product_id
where s.order_date >= mem.join_date and date_part(month, s.order_date) = 1
group by s.customer_id;
 

/*11) Join All The Things, Danny also requires further information about the ranking of customer products, but he purposely 
      does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are 
      not yet part of the loyalty program.*/

select 
    s.customer_id, 
    s.order_date,
    m.product_name,
    m.price,
    case 
        when s.order_date >= mem.join_date then 'Y'
        else 'N'
    end member
from
    sales s
left join menu as m on m.product_id = s.product_id
left join members as mem on s.customer_id = mem.customer_id


--12) Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member 
      purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
      
with cte as (select 
    s.customer_id, 
    s.order_date,
    m.product_name,
    m.price,
    case 
        when s.order_date >= mem.join_date then 'Y'
        else 'N'
    end member
from
    sales s
left join menu as m on m.product_id = s.product_id
left join members as mem on s.customer_id = mem.customer_id)
select 
    *,
    case
        when member = 'N' then null
        else dense_rank() over(partition by customer_id,member order by order_date)
    end as ranking
from cte;

