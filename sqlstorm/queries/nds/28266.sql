
WITH address_info AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
        ca_city, 
        ca_state, 
        ca_zip 
    FROM customer_address
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        c.c_birth_month, 
        c.c_birth_year, 
        cd.cd_gender 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
date_info AS (
    SELECT 
        d.d_date_sk, 
        d.d_year, 
        d.d_month_seq, 
        d.d_day_name 
    FROM date_dim d
), 
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales 
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
)
SELECT 
    ci.full_name,
    ai.full_address,
    di.d_year,
    di.d_day_name,
    ss.total_quantity,
    ss.total_sales,
    CASE 
        WHEN ci.c_birth_month = di.d_month_seq THEN 'Birthday Month' 
        ELSE 'Other Month' 
    END AS birthday_status
FROM customer_info ci
JOIN address_info ai ON ci.c_customer_sk = ai.ca_address_sk
JOIN date_info di ON di.d_date_sk IN (SELECT DISTINCT ws.ws_sold_date_sk FROM web_sales ws)
JOIN sales_summary ss ON ss.ws_sold_date_sk = di.d_date_sk
WHERE ci.cd_gender = 'M' 
AND ai.ca_state = 'CA' 
AND ss.total_sales > 100
ORDER BY ss.total_sales DESC;
