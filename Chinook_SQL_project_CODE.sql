-- obj question 1

-- SELECT
--   COUNT(*) - COUNT(first_name) AS nulls_in_first_name,
--   COUNT(*) - COUNT(last_name) AS nulls_in_last_name,
--   COUNT(*) - COUNT(company) AS nulls_in_company,
--   COUNT(*) - COUNT(address) AS nulls_in_address,
--   COUNT(*) - COUNT(city) AS nulls_in_city,
--   COUNT(*) - COUNT(state) AS nulls_in_state,
--   COUNT(*) - COUNT(country) AS nulls_in_country,
--   COUNT(*) - COUNT(postal_code) AS nulls_in_postal_code,
--   COUNT(*) - COUNT(phone) AS nulls_in_phone,
--   COUNT(*) - COUNT(fax) AS nulls_in_fax,
--   COUNT(*) - COUNT(email) AS nulls_in_email,
--   COUNT(*) - COUNT(support_rep_id) AS nulls_in_support_rep_id
-- FROM customer;

-- select 
-- 	  count(*) - count(invoice_date) as null_invoice_date,
--       count(*) - count(billing_address) as null_billing_address,
--       count(*) - count(billing_city) as null_billing_city,
--       count(*) - count(billing_state) as null_billing_state,
--       count(*) - count(billing_country) as null_billing_country,
--       count(*) - count(billing_postal_code) as null_billing_postal_code,
--       count(*) - count(total) as null_total
-- from invoice;

-- SELECT
--   COUNT(*) - COUNT(invoice_id) AS null_invoice_id,
--   COUNT(*) - COUNT(track_id) AS null_track_id,
--   COUNT(*) - COUNT(unit_price) AS null_unit_price,
--   COUNT(*) - COUNT(quantity) AS null_quantity
-- FROM invoice_line;

-- SELECT
--   COUNT(*) - COUNT(name) AS null_name,
--   COUNT(*) - COUNT(album_id) AS null_album_id,
--   COUNT(*) - COUNT(media_type_id) AS null_media_type_id,
--   COUNT(*) - COUNT(genre_id) AS null_genre_id,
--   COUNT(*) - COUNT(composer) AS null_composer,
--   COUNT(*) - COUNT(milliseconds) AS null_milliseconds,
--   COUNT(*) - COUNT(bytes) AS null_bytes,
--   COUNT(*) - COUNT(unit_price) AS null_unit_price
-- FROM track;

-- SELECT invoice_id, track_id, COUNT(*) AS dup_count
-- FROM invoice_line
-- GROUP BY invoice_id, track_id
-- HAVING COUNT(*) > 1;

-- SELECT playlist_id, track_id, COUNT(*) AS dup_count
-- FROM playlist_track
-- GROUP BY playlist_id, track_id
-- HAVING COUNT(*) > 1;
 
 -- obj question 2
 
SELECT 
    t.track_id,
    t.name AS track_name,
    g.name AS genre_name,
    a.name AS artist_name,
    COUNT(il.track_id) AS total_purchases
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
WHERE i.billing_country = 'USA'
GROUP BY t.track_id, t.name, g.name, a.name
ORDER BY total_purchases DESC
LIMIT 5;


-- obj question 3

select country, state ,city, count(*) as total_cust
from customer
group by country, state ,city
order by total_cust desc
limit 10;


-- obj question 4


select billing_country as country, billing_state as state ,billing_city as city,count(*) as total_invoices,sum(total) as total_revenue
from invoice
group by billing_country, billing_state,billing_city
order by total_invoices desc, total_revenue desc
limit 10;



-- obj question 5


with cte as (
select c.customer_id,c.first_name,c.last_name,c.country,sum(i.total) as total_reven, 
rank() over(partition by c.country order by sum(i.total) desc) as rnk
from customer c 
join invoice i 
on c.customer_id = i.customer_id
group by c.customer_id,c.first_name,c.last_name,c.country)
select * from cte -- used rank() to include ties as well
where rnk<=5
order by total_reven desc,rnk desc;


-- obj question 6


with cte_two as (
select c.customer_id,c.first_name,c.last_name,t.name,
sum(il.quantity) as total_quantity, 
dense_rank() over(partition by c.customer_id order by sum(il.quantity) desc) as rnkd
from customer c 
join invoice i 
on c.customer_id = i.customer_id
join invoice_line il 
on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
group by c.customer_id,c.first_name,c.last_name,t.name)
select * from  cte_two
where rnkd = 1
order by total_quantity desc;



-- 6
SELECT customer_id, COUNT(DISTINCT track_id) AS unique_tracks, SUM(quantity) AS total_qty
FROM invoice_line
JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
GROUP BY customer_id;


-- obj question 7


select c.customer_id, concat(c.first_name,' ',c.last_name) as cust_name, count(i.invoice_id) as total_orders, 
       round(sum(i.total)) as total_spent, round(avg(i.total)) as avg_spent
from customer c join invoice i on c.customer_id = i.customer_id
group by c.customer_id, cust_name
order by total_orders desc, avg_spent desc
limit 5;



-- obj question 8


WITH latest AS (
    SELECT MAX(DATE(invoice_date)) AS latest_date
    FROM invoice
),
active_customer AS (
    SELECT DISTINCT customer_id
    FROM invoice, latest
    WHERE invoice_date >= DATE_SUB(latest_date, INTERVAL 90 DAY)
)
SELECT 
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT COUNT(*) 
     FROM customer c
     WHERE NOT EXISTS (
         SELECT 1 FROM active_customer ac
         WHERE ac.customer_id = c.customer_id
     )
    ) AS churned_customers,
    ROUND(
        (SELECT COUNT(*) 
         FROM customer c
         WHERE NOT EXISTS (
            SELECT 1 FROM active_customer ac
            WHERE ac.customer_id = c.customer_id
         )
        ) / (SELECT COUNT(*) FROM customer) * 100, 2
    ) AS churn_percentage;



----- 180-days period

WITH latest AS (
    SELECT MAX(DATE(invoice_date)) AS latest_date
    FROM invoice
),
active_customer AS (
    SELECT DISTINCT customer_id
    FROM invoice, latest
    WHERE invoice_date >= DATE_SUB(latest_date, INTERVAL 180 DAY)
)
SELECT 
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT COUNT(*) 
     FROM customer c
     WHERE NOT EXISTS (
         SELECT 1 FROM active_customer ac
         WHERE ac.customer_id = c.customer_id
     )
    ) AS churned_customers,
    ROUND(
        (SELECT COUNT(*) 
         FROM customer c
         WHERE NOT EXISTS (
            SELECT 1 FROM active_customer ac
            WHERE ac.customer_id = c.customer_id
         )
        ) / (SELECT COUNT(*) FROM customer) * 100, 2
    ) AS churn_percentage;




-- obj question 9


with genre_sales as(
select g.genre_id,g.name, sum(il.unit_price*il.quantity) as genre_revenue
from invoice i join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = "USA"
group by g.genre_id,g.name
),
usa_total_sales as(
select sum(il.unit_price*il.quantity) as total_usa_revenue
from invoice_line il join invoice i on il.invoice_id = i.invoice_id
where i.billing_country = "USA")
select gs.genre_id,gs.name, (gs.genre_revenue/uts.total_usa_revenue)*100 as percentage_contribution
from genre_sales gs, usa_total_sales uts
order by genre_revenue desc,percentage_contribution desc
limit 5;

select a1.artist_id,a1.name, sum(il.unit_price*il.quantity) as artist_revenue
from invoice i join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album a on t.album_id = a.album_id
join artist a1 on a.artist_id = a1.artist_id
where i.billing_country = "USA"
group by a1.artist_id,a1.name
order by artist_revenue desc
limit 5;


-- obj question 10


select c.customer_id, concat(c.first_name,' ',c.last_name) as full_name, count(distinct g.genre_id) as genre_count
from customer c join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
group by c.customer_id, full_name
having genre_count >=3
order by genre_count desc
limit 5;



-- obj question 11

select g.genre_id, g.name, sum(il.unit_price*il.quantity) as sales_totals, rank() over(order by sum(il.unit_price*il.quantity) desc) as rnk
from invoice i join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = "USA"
group by g.genre_id, g.name
order by sales_totals desc;


-- obj question 12


WITH latest AS (
    SELECT MAX(DATE(invoice_date)) AS now_date 
    FROM invoice
),
customer_last_purchase AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) AS cust_name,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN invoice i 
        ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
),
purchase_customers AS (
    SELECT DISTINCT customer_id
    FROM invoice i
    CROSS JOIN latest l
    WHERE i.invoice_date >= DATE_SUB(l.now_date, INTERVAL 90 DAY)
)
SELECT 
    clp.customer_id,
    clp.cust_name,
    clp.last_purchase_date
FROM customer_last_purchase clp
WHERE NOT EXISTS (
    SELECT 1 
    FROM purchase_customers pc
    WHERE pc.customer_id = clp.customer_id
)
ORDER BY clp.last_purchase_date
LIMIT 5;



-- SUBJECTIVE PART

-- Subj question 1


select a.album_id, a.title as album_title, g.genre_id, g.name as genre_name, a1.name as artist_name, sum(il.unit_price*il.quantity) as album_sales
from invoice i join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album a on t.album_id = a.album_id
join artist a1 on a.artist_id = a1.artist_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = "USA"
group by a.album_id,album_title,g.genre_id,genre_name,artist_name
order by album_sales desc
limit 10;



-- Subj question 2


select g.genre_id, g.name as genre_name, sum(il.unit_price*il.quantity) as genres_sales, rank() over(order by sum(il.unit_price*il.quantity) desc) as genre_rnk
from invoice i join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where i.billing_country <> "USA"
group by g.genre_id, genre_name
order by genres_sales desc
limit 5;


-- Subj question 3 


select c.customer_id, concat(first_name,' ',last_name) as user_full_names, min(date(i.invoice_date)) as first_payment
from customer c join invoice i on c.customer_id = i.customer_id
group by c.customer_id,user_full_names
order by first_payment desc;

select case 
       when year(i.invoice_date) in (2017,2018) then 'Long-Term Users'
       else 'New Users' end as Customer_type, count(distinct i.invoice_id) as total_orders,sum(total) as spending_amout, avg(total) as avg_spent_value
from invoice i join customer c on i.customer_id = c.customer_id
group by Customer_type;
 
 
 
-- Subj question 4


with affinity_cte as(
select i.invoice_id,g.name as genre_name, a1.name as artist_name,a.title from invoice i 
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
join album a on t.album_id = a.album_id
join artist a1 on a.artist_id = a1.artist_id
) 
select ac.genre_name as genre_1, ac1.genre_name as genre_2, count(*) as frequent_genre_purchase
from affinity_cte ac join affinity_cte ac1 on ac.invoice_id = ac1.invoice_id and ac.genre_name<ac1.genre_name
group by ac.genre_name, ac1.genre_name
order by frequent_genre_purchase desc
limit 5;

with affinity_cte as(
select i.invoice_id,g.name as genre_name, a1.name as artist_name,a.title from invoice i 
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
join album a on t.album_id = a.album_id
join artist a1 on a.artist_id = a1.artist_id
) 
select ac2.artist_name as artist_1, ac3.artist_name as artist_2, count(*) as artist_purchases
from affinity_cte ac2 join affinity_cte ac3 on ac2.invoice_id = ac3.invoice_id and ac2.artist_name<ac3.artist_name
group by ac2.artist_name, ac3.artist_name
order by artist_purchases desc
limit 5;

with affinity_cte as(
select i.invoice_id,g.name as genre_name, a1.name as artist_name,a.title as album_name from invoice i 
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
join album a on t.album_id = a.album_id
join artist a1 on a.artist_id = a1.artist_id
) 
select ac4.album_name as album_1, ac5.album_name as album_2, count(*) as albums_purchases
from affinity_cte ac4 join affinity_cte ac5 on ac4.invoice_id = ac5.invoice_id and ac4.album_name<ac5.album_name
group by ac4.album_name, ac5.album_name
order by albums_purchases desc
limit 5;



-- Subj question 5


WITH latest_invoice AS (
  SELECT 
    customer_id,
    MAX(invoice_date) AS last_purchase
  FROM invoice
  GROUP BY customer_id
),

-- Step 2: Churn status based on 90-day rule
churn_check AS (
  SELECT 
    customer_id,
    last_purchase,
    CASE 
      WHEN last_purchase < DATE_SUB((SELECT MAX(invoice_date) FROM invoice), INTERVAL 90 DAY)
      THEN 'Churned'
      ELSE 'Active'
    END AS churn_status
  FROM latest_invoice
),

-- Step 3: Aggregate per country
summary AS (
  SELECT 
    i.billing_country AS country,
    COUNT(DISTINCT i.customer_id) AS total_customers,
    ROUND(SUM(i.total), 2) AS total_revenue,
    COUNT(i.invoice_id) AS total_orders,
    ROUND(AVG(i.total), 2) AS avg_order_value
  FROM invoice i
  GROUP BY i.billing_country
),

-- Step 4: Churn status count per country
churn_stats AS (
  SELECT 
    i.billing_country AS country,
    cc.churn_status,
    COUNT(DISTINCT i.customer_id) AS user_count
  FROM invoice i
  JOIN churn_check cc ON i.customer_id = cc.customer_id
  GROUP BY i.billing_country, cc.churn_status
)

-- Step 5: Final join for full summary
SELECT 
  s.country,
  s.total_customers,
  s.total_revenue,
  s.total_orders,
  s.avg_order_value,
  COALESCE(SUM(CASE WHEN cs.churn_status = 'Active' THEN cs.user_count END), 0) AS active_users,
  COALESCE(SUM(CASE WHEN cs.churn_status = 'Churned' THEN cs.user_count END), 0) AS churned_users,
  ROUND(
    100 * COALESCE(SUM(CASE WHEN cs.churn_status = 'Churned' THEN cs.user_count END), 0) / s.total_customers,
    2
  ) AS churn_rate_percent
FROM summary s
LEFT JOIN churn_stats cs ON s.country = cs.country
GROUP BY s.country, s.total_customers, s.total_revenue, s.total_orders, s.avg_order_value
ORDER BY churn_rate_percent DESC;



-- Subj question 6


WITH last_purchases AS (
  SELECT customer_id, MAX(DATE(invoice_date)) AS last_bought
  FROM invoice
  GROUP BY customer_id
),
churn_status AS (
  SELECT 
    lp.customer_id,
    lp.last_bought,
    CASE 
      WHEN lp.last_bought < DATE_SUB((SELECT MAX(DATE(invoice_date)) FROM invoice), INTERVAL 90 DAY)
      THEN 'High Risk - Churned'
      ELSE 'Low Risk - Active'
    END AS risk_status
  FROM last_purchases lp
),
customer_spending AS (
  SELECT 
    i.customer_id,
    c.country,
    COUNT(i.invoice_id) AS total_orders,
    SUM(i.total) AS total_spent,
    AVG(i.total) AS avg_order_value
  FROM invoice i
  JOIN customer c ON i.customer_id = c.customer_id
  GROUP BY i.customer_id, c.country
)
SELECT 
  cs.customer_id,
  cs.country,
  cs.total_orders,
  cs.total_spent,
  cs.avg_order_value,
  cr.risk_status
FROM customer_spending cs
JOIN churn_status cr ON cs.customer_id = cr.customer_id
ORDER BY cr.risk_status DESC, cs.total_spent ASC;



-- Subj question 7


with full_customer_details as (
select c.customer_id, concat(c.first_name,' ',c.last_name) as users_names,
	   min(date(i.invoice_date)) as first_purchased, max(date(i.invoice_date)) as recent_purchase,
       datediff(min(date(i.invoice_date)), max(date(i.invoice_date))) as tenure_days,
       sum(i.total) as total_spend, avg(i.total) as aveg_spend, 
       count(i.invoice_id) as frequent_purchases
from customer c join invoice i on c.customer_id = i.customer_id
group by c.customer_id,users_names
),
cust_status as (
select distinct customer_id
from invoice 
where invoice_date>= date_sub('2020-12-30',interval 90 day) 
),
final_cte as(
select fcd.*, case when fcd.customer_id in (select customer_id from cust_status) then 'Active Only' 
                   else 'Churned One' end as Customer_Status
from full_customer_details fcd
)
select * from final_cte
order by total_spend desc, tenure_days desc;



-- Subj question 10


ALTER TABLE album
ADD COLUMN ReleaseYear INT;

-- Subj question 11



with last_ques as (
select c.country, c.customer_id,sum(i.total) as the_total_spent,sum(il.quantity) as tracks_count
from customer c join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
group by c.country, c.customer_id)

select country, avg(the_total_spent) as avg_amount, count(customer_id) as count_customers, avg(tracks_count) as avg_tracks_purchased
from last_ques
group by country
order by avg_amount desc;


