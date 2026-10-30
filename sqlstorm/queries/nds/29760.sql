WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_info AS (
    SELECT d.d_date, 
           d.d_day_name, 
           d.d_month_seq
    FROM date_dim d
    WHERE d.d_year = 2001
),
sales_info AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_web_page_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    di.d_day_name,
    di.d_month_seq,
    si.total_quantity,
    si.total_sales,
    CASE 
        WHEN si.total_sales > 1000 THEN 'High Value Customer'
        WHEN si.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM customer_info ci
JOIN date_info di ON ci.c_customer_sk = di.d_month_seq  
JOIN sales_info si ON ci.c_customer_sk = si.ws_web_page_sk  
WHERE ci.cd_gender = 'F' AND ci.cd_marital_status = 'M'
ORDER BY si.total_sales DESC;