--Monday coffee Data Analysis :
select * from city;
select * from customers;
select * from products;
select * from sales;

--Reports and Data Analysis :

-- Q.1
-- Coffee consumers count 
-- How many people in each city are estimated to consume coffee , given that 25% of the population does .
select city_name,round((0.25*population)/1000000,2)::text || ' M' as pop_consuming_coffee
from city
group by 1,2
order by 2 desc; 

-- Q.2
--  Total Revenue from Coffee Sales
--  What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

--
select extract (year from sale_date) as year,
		extract (quarter from sale_date) as quarter ,
		sum(total) as revenue
from sales
WHERE extract (year from sale_date)=2023 and extract (quarter from sale_date)=4
group by 1,2 ;


--
select extract (year from s.sale_date) as year,
		extract (quarter from s.sale_date) as quarter ,
		ci.city_name,sum(total) as revenue
from sales s
join customers c on c.customer_id=s.customer_id
join city ci on c.city_id=ci.city_id
WHERE extract (year from s.sale_date)=2023 and extract (quarter from s.sale_date)=4
group by 1,2,3
order by 4 desc;


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select p.product_name , count(*) as sales_count
from products p
left join sales s on p.product_id=s.product_id
group by 1
order by 2 desc


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

select ci.city_name, COUNT(distinct c.customer_id) as customer_count
		, round( sum(total)::numeric/COUNT(distinct c.customer_id)::numeric ,2) as average
from sales s
join customers c on c.customer_id=s.customer_id
join city ci on c.city_id=ci.city_id
group by 1
order by 3 ;


-- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
select ci.city_name,round(ci.population/1000000.00,2)::text || ' M' as population ,
		round((ci.population*0.25)/1000000,2)::text || ' M' as coffee_consumers ,
		count(distinct s.customer_id) as unique_cx
from sales s
join customers c on c.customer_id=s.customer_id
join city ci on c.city_id=ci.city_id
group by 1,2,3

-- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
WITH rank_tb
 as 
(
select ci.city_name, p.product_name , count(*) as total_orders,
		DENSE_RANK() OVER(PARTITION BY 	CITY_NAME ORDER BY count(*) DESC) AS RANK
from products p
join sales s on p.product_id=s.product_id
join customers c on c.customer_id=s.customer_id
join city ci on c.city_id=ci.city_id
group by 1,2
)
select * from rank_tb where rank<=3

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select ci.city_name ,count(distinct s.customer_id) as unique_cx
from products p
join sales s on p.product_id=s.product_id
join customers c on c.customer_id=s.customer_id
join city ci on c.city_id=ci.city_id
where p.product_name ilike '%coffee%'
group by 1;

-- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

WITH avg_sale_tb
AS
(
SELECT ci.city_name, SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as distinct_cx,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_per_cx
FROM sales as s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city  ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
)
SELECT c.city_name, c.estimated_rent, a.distinct_cx, a.avg_sale_per_cx,
		ROUND(c.estimated_rent::numeric/a.distinct_cx::numeric, 2) as avg_rent_per_cx
FROM city c
JOIN avg_sale_tb  a ON c.city_name = a.city_name
ORDER BY 4 desc

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
WITH
monthly_sales
AS
(
SELECT ci.city_name, EXTRACT(YEAR FROM sale_date) as year, 
		EXTRACT(MONTH FROM sale_date) as month, SUM(s.total) as current_month_sale ,
		LAG(SUM(s.total), 1) OVER(PARTITION BY city_name ORDER BY EXTRACT(YEAR FROM sale_date), EXTRACT(MONTH FROM sale_date)) 
		as last_month_sale
FROM sales as s
JOIN customers as c ON c.customer_id = s.customer_id
JOIN city as ci ON ci.city_id = c.city_id
GROUP BY 1, 2, 3
ORDER BY 1,2,3
)

SELECT city_name, year, month, current_month_sale, last_month_sale,
		ROUND((current_month_sale - last_month_sale)::numeric/last_month_sale::numeric * 100, 2) as growth_ratio
FROM monthly_sales
WHERE last_month_sale IS NOT NULL	;

/*
-- Q.10
--	Market Potential Analysis
--	Identify top 3 city based on highest sales, return city name, total sale, total rent,total customers,
	estimated coffee consumer
*/
WITH total_sale_tb
AS
(
SELECT ci.city_name, 
		COUNT(DISTINCT s.customer_id) as distinct_cx ,SUM(s.total) as total_sale
FROM sales as s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city  ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
)
SELECT c.city_name, ROUND((c.population * 0.25)/1000000, 2)::text || 'M' as estimated_coffee_consumers ,
		t.distinct_cx , t.total_sale , c.estimated_rent
FROM city c
JOIN total_sale_tb  t ON c.city_name = t.city_name
ORDER BY 4 desc,5 desc

/*
Recommendations :

TOP 1: PUNE
* Maximum total sales are generated in pune .
* Estimated rent is low .
* With high numbers of total customers .

TOP 2: JAIPUR
* estimated rent is too low .
* maximum numbers of total customers are in jaipur .
* high total sales are generated compared to rent .

TOP 3: DELHI
* maximum numbers of estimated coffee consumers are found in Delhi with population of 7.75 M .
* very high number of total customers .
* good ratio of total_sales to estimated_rent .