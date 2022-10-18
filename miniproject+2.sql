use miniproject2;
select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;





-- q1.Join all the tables and create a new table called combined_table.
-- (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

create table combined_table
(select  * from market_fact
inner join cust_dimen using (cust_id)
inner join orders_dimen using (ord_id)
inner join prod_dimen using (prod_id)
inner join shipping_dimen using (ship_id,order_id));



-- q2.Find the top 3 customers who have the maximum number of orders
select * from combined_table;
select sum(order_quantity), cust_id,customer_name from combined_table
group by customer_name
order by sum(order_quantity) desc limit 1,3;

-- q3.Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.

set sql_safe_updates=0;
alter table combined_table
add column ship_date1 date; -- created new column
update combined_table set ship_date1=Date(str_to_date(ship_date,'%d-%m-%Y'));-- inserted value in proper format
alter table combined_table
add column order_date1 date; -- created new column
update combined_table set order_date1=Date(str_to_date(order_date,'%d-%m-%Y'));-- inserted value in proper format


alter table combined_table
add column daystakenfordelivery int;
update combined_table
set daystakenfordelivery=datediff(ship_date1,order_date1);



-- q4.Find the customer whose order took the maximum time to get delivered.

select customer_name,daystakenfordelivery from combined_table
order by daystakenfordelivery desc limit 1;

-- q5.Retrieve total sales made by each product from the data (use Windows function).

select distinct prod_id,sum(sales) over(partition by prod_id ) from combined_table;

-- q6.Retrieve total profit made from each product from the data (use windows function)


select distinct prod_id,sum(profit) over(order by prod_id) from combined_table;

-- q7.Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
select * from combined_table;

select count(distinct cust_id) total_jan_cust from combined_table
where order_date1 between '2011-1-1' and '2011-1-31';



-- q8.Retrieve month-by-month customer retention rate since the start of the business.(using views)

create view visit as
(select customer_name,order_date,month(order_date) month
from combined_table
order by customer_name,order_date);

create view following as
(select *,lead(order_date) over() nextvisit from visit);

create view retention as
(select *,datediff(nextvisit,order_date) retention_value from following);

create view retentionfinal as
(select *,
(case
when retention_value<0 then null
when retention_value between 0 and 30 then 'retained'
when retention_value between 31 and 90 then 'irregular'
else 'churned'
end) retention_status
from retention);

select month,retention_status,
(count(retention_status)/(select count(retention_status) from retentionfinal where month=rf.month))*100  as retention_rate_percentage
from retentionfinal rf
where retention_status='retained'
group by month,retention_status
order by month;