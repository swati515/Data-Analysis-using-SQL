-- creating database
create database amazon_analysis;


-- creating schema
create schema amazon_brazil;


-- 1. creating table customers
create table amazon_brazil.customers
(
customer_id varchar(250) primary key, 
customer_unique_id varchar(250),	
customer_zip_code_prefix int
);
select * from amazon_brazil.customers;


-- 2. creating table order_items
create table amazon_brazil.order_items
(
order_id varchar (250),
order_item_id int,
product_id varchar (250),
seller_id varchar (250),
shipping_limit_date timestamp,
price float,
freight_value float
);
select * from amazon_brazil.order_items;  


--3. creating table payments
create table amazon_brazil.payments
(
order_id varchar (250),
payment_sequential int,
payment_type varchar (250),
payment_installments int,
payment_value float
);
select * from amazon_brazil.payments;


-- 4. creating table orders
create table amazon_brazil.orders
(
order_id varchar (250) primary key,
customer_id varchar (250),
order_status varchar (250),
order_purchase_timestamp timestamp,
order_approved_at timestamp,
order_delivered_carrier_date timestamp,
order_delivered_customer_date timestamp,
order_estimated_delivery_date timestamp
);
select * from amazon_brazil.orders;


-- 5. creating table product
create table amazon_brazil.product
(
product_id varchar (250) primary key,
product_category_name varchar (250), 
product_name_lenght int,	
product_description_lenght int, 
product_photos_qty int,
product_weight_g int,
product_length_cm int,	
product_height_cm int,
product_width_cm int
);
select * from amazon_brazil.product;


-- 6. creating table seller
create table amazon_brazil.seller
(
seller_id varchar (250) primary key,
seller_zip_code_prefix int
);
select * from amazon_brazil.seller;


-- Analysis 1
-- 1.1 To simplify its financial reports, Amazon India needs to standardize payment values. Round the average 
--     payment values to integer (no decimal) for each payment type and display the results sorted in ascending 
--     order. Output: payment_type, rounded_avg_payment

select payment_type, 
round(avg(payment_value)) as rounded_avg_payment
from amazon_brazil.payments
where payment_type <> 'not_defined'
group by payment_type
order by rounded_avg_payment;


-- 1.2 To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type. 
--     Calculate the percentage of total orders for each payment type, rounded to one decimal place, and display 
--     them in descending order. Output: payment_type, percentage_orders

select payment_type,
round(count(order_id) * 100.0/(select count(*) from amazon_brazil.payments),1) 
as percentage_orders
from amazon_brazil.payments
where payment_type <> 'not_defined'
group by payment_type
order by percentage_orders desc;


-- 1.3 Amazon India seeks to create targeted promotions for products within specific price ranges. Identify all 
--     products priced between 100 and 500 BRL that contain the word 'Smart' in their name. Display these products, 
--     sorted by price in descending order. Output: product_id, price

select pr.product_id, o.price as price
from amazon_brazil.order_items o
join amazon_brazil.product pr
on o.product_id = pr.product_id
where o.price between 100 and 500 
and product_category_name like lower('%Smart%')
order by price desc;


-- 1.4 To identify seasonal sales patterns, Amazon India needs to focus on the most successful months. Determine 
--     the top 3 months with the highest total sales value, rounded to the nearest integer. Output: month, total_sales

select extract(month from o.order_purchase_timestamp) as month,
round(sum(oi.price)) as total_sales
from amazon_brazil.orders o
join amazon_brazil.order_items oi
on o.order_id = oi.order_id
group by month
order by total_sales desc
limit 3;

 
-- 1.5 Amazon India is interested in product categories with significant price variations. Find categories where 
--     the difference between the maximum and minimum product prices is greater than 500 BRL.
--     Output: product_category_name, price_difference

select p.product_category_name, max(oi.price) - min(oi.price)
as price_difference
from amazon_brazil.product p
join amazon_brazil.order_items oi
on p.product_id = oi.product_id
group by p.product_category_name
having max(oi.price) - min(oi.price) > 500;


-- 1.6 To enhance the customer experience, Amazon India wants to find which payment types have the most consistent 
--     transaction amounts. Identify the payment types with the least variance in transaction amounts, sorting by 
--     the smallest standard deviation first. Output: payment_type, std_deviation

select payment_type, round(stddev(payment_value)) as std_deviation
from amazon_brazil.payments
where payment_type <> 'not_defined'
group by payment_type
order by std_deviation;


-- 1.7 Amazon India wants to identify products that may have incomplete name in order to fix it from their end. 
--     Retrieve the list of products where the product category name is missing or contains only a single character.
--     Output: product_id, product_category_name

select product_id, product_category_name
from amazon_brazil.product
where product_category_name is null
or length(product_category_name) = 1;


-- Analysis 2
-- 2.1 Amazon India wants to understand which payment types are most popular across different order value segments 
--     (e.g., low, medium, high). Segment order values into three ranges: orders less than 200 BRL, between 200 and 
--     1000 BRL, and over 1000 BRL. Calculate the count of each payment type within these ranges and display the 
--     results in descending order of count. Output: order_value_segment, payment_type, count

select
case
when payment_value > 1000 then 'high'
when payment_value between 200 and 1000 then 'medium'
when payment_value < 200 then 'low'
else 'NA'
end as order_value_segment, payment_type,
count(payment_type)
from amazon_brazil.payments
group by order_value_segment, payment_type
order by count desc;


-- 2.2 Amazon India wants to analyse the price range and average price for each product category. Calculate the 
--     minimum, maximum, and average price for each category, and list them in descending order by the average 
--     price. Output: product_category_name, min_price, max_price, avg_price
 
select p.product_category_name, 
min(o.price) as min_price, 
max(o.price) as max_price, 
round(avg(o.price)) as avg_price
from amazon_brazil.product p 
join amazon_brazil.order_items o
on p.product_id = o.product_id
group by product_category_name
order by avg_price desc;


-- 2.3 Amazon India wants to identify the customers who have placed multiple orders over time. Find all customers 
--     with more than one order, and display their customer unique IDs along with the total number of orders they 
--     have placed. Output: customer_unique_id, total_orders.

select c.customer_unique_id, 
count(o.order_id) as total_orders
from amazon_brazil.customers c
join amazon_brazil.orders o
on c.customer_id = o.customer_id
group by c.customer_unique_id
having count(o.order_id) > 1;


-- 2.4 Amazon India wants to categorize customers into different types ('New – order qty. = 1' ;  'Returning' –order 
--     qty. 2 to 4;  'Loyal' – order qty. >4) based on their purchase history. Use a temporary table to define these 
--     categories and join it with the customers table to update and display the customer types. 
--     Output: customer_id, customer_type

create temporary table customer_categories as
select customer_id,
case
when count(order_id) = 1 then 'New'
when count(order_id) between 2 and 4 then 'Returning'
when count(order_id) > 4 then 'Loyal'
else 'NA'
end as customer_type
from amazon_brazil.orders
group by customer_id;
select c.customer_id, cc.customer_type
from amazon_brazil.customers c
join customer_categories cc 
on c.customer_id = cc.customer_id;


-- 2.5 Amazon India wants to know which product categories generate the most revenue. Use joins between the tables to 
--     calculate the total revenue for each product category. Display the top 5 categories. 
--     Output: product_category_name, total_revenue

select p.product_category_name, round(sum(o.price)) as total_revenue
from amazon_brazil.product p
join amazon_brazil.order_items o
on p.product_id = o.product_id
group by product_category_name
order by total_revenue desc
limit 5;


-- Analysis 3
-- 3.1 The marketing team wants to compare the total sales between different seasons. Use a subquery 
--     to calculate total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase 
--     dates, and display the results. Spring is in the months of March, April and May. Summer is from 
--     June to August and Autumn is between September and November and rest months are Winter. Output: season, total_sales

select season, round(sum(oi.price)) as total_sales 
from
(
select o.order_id,
case
when extract(month from order_purchase_timestamp) in (3, 4, 5)  then 'Spring'
when extract(month from order_purchase_timestamp) in (6, 7, 8) then 'Summer'
when extract(month from order_purchase_timestamp) in (9, 10, 11) then 'Autumn'
else 'Winter'
end as season
from amazon_brazil.orders o
) as order_season
join amazon_brazil.order_items oi
on order_season.order_id = oi.order_id
group by season;


-- 3.2 The inventory team is interested in identifying products that have sales volumes above the overall 
--     average. Write a query that uses a subquery to filter products with a total quantity sold above the 
--     average quantity. Output: product_id, total_quantity_sold 

select product_id, total_quantity_sold
from 
(
select product_id, count(distinct order_id) as total_quantity_sold
from amazon_brazil.order_items
group by product_id
) as product_totals
where total_quantity_sold > 
(select avg(total_quantity_sold)
from 
(select product_id, count(distinct order_id) as total_quantity_sold
from amazon_brazil.order_items
group by product_id
) as avg_totals
)
order by total_quantity_sold desc;


-- 3.3 To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over 
--     the past year. Run a query to calculate total revenue generated each month and identify periods of 
--     peak and low sales. Export the data to Excel and create a graph to visually represent revenue changes 
--     across the months. Output: month, total_revenue

select extract(month from order_purchase_timestamp) as month,
round(sum(oi.price)) as total_revenue
from amazon_brazil.orders o
join amazon_brazil.order_items oi
on o.order_id = oi.order_id
where extract(year from (order_purchase_timestamp)) = 2018
group by month;


--3.4 A loyalty program is being designed for Amazon India. Create a segmentation based on purchase frequency: 
--    ‘Occasional’ for customers with 1-2 orders, ‘Regular’ for 3-5 orders, and ‘Loyal’ for more than 5 orders. 
--    Use a CTE to classify customers and their count and generate a chart in Excel to show the proportion of 
--    each segment. Output: customer_type, count

with customer_segmentation as 
(
select customer_id, count(order_id) as count,
case 
when count(order_id) > 5 then 'Loyal'
when count(order_id) between 3 and 5 then 'Regular'
when count(order_id) between 1 and 2 then 'Ocassional'
else 'NA'
end as customer_type
from amazon_brazil.orders 
group by customer_id
)
select customer_type, count(customer_type) as count from customer_segmentation
group by customer_type;


-- 3.5 Amazon wants to identify high-value customers to target for an exclusive rewards program. You are 
--     required to rank customers based on their average order value (avg_order_value) to find the top 20 
--     customers. Output: customer_id, avg_order_value, and customer_rank

select o.customer_id, avg(oi.price) as avg_order_value,
rank () over (order by avg(oi.price) desc) as customer_rank
from amazon_brazil.orders o
join amazon_brazil.order_items oi
on o.order_id = oi.order_id 
group by o.customer_id
order by avg_order_value desc
limit 20;


-- 3.6 Amazon wants to analyze sales growth trends for its key products over their lifecycle. Calculate monthly 
--     cumulative sales for each product from the date of its first sale. Use a recursive CTE to compute the 
--     cumulative sales (total_sales) for each product month by month. Output: product_id, sale_month, and total_sales.

with monthly_sales as
(
select oi.product_id, 
extract (month from o.order_purchase_timestamp) as sale_month,
sum(oi.price) as monthly_sale
from amazon_brazil.orders o
join amazon_brazil.order_items oi
on o.order_id = oi.order_id
group by product_id, sale_month
)
select product_id, sale_month, 
round(sum(monthly_sale) over (partition by product_id order by sale_month)) as total_sales
from monthly_sales;


-- 3.7 To understand how different payment methods affect monthly sales growth, Amazon wants to compute the 
--     total sales for each payment method and calculate the month-over-month growth rate for the past year. 
--     Write query to first calculate total monthly sales for each payment method, then compute the percentage 
--     change from the previous month. Output: payment_type, sale_month, monthly_total, monthly_change.

with total_sale as
(
select p.payment_type, 
extract (month from o.order_purchase_timestamp) as sale_month,
round(sum(oi.price)) as monthly_total
from amazon_brazil.orders o
join amazon_brazil.order_items oi
on o.order_id = oi.order_id
join amazon_brazil.payments p
on o.order_id = p.order_id
where extract (year from o.order_purchase_timestamp) = 2018
group by p.payment_type, sale_month
)
select payment_type, sale_month, monthly_total,
case
when lag(monthly_total) over () = 0 then null
else
round((monthly_total - lag(monthly_total) over())/lag(monthly_total) over() * 100)
end as monthly_change
from total_sale;

  






















































	  