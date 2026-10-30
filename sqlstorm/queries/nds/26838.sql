
WITH demographics AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM customer_address ca
),
sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
demographic_address_sales AS (
    SELECT 
        d.c_customer_sk,
        d.full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        s.total_sales,
        s.order_count
    FROM demographics d
    JOIN address a ON d.c_customer_sk = a.ca_address_sk
    LEFT JOIN sales s ON d.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    cd.cd_gender,
    COUNT(*) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ds.total_sales) AS total_revenue,
    AVG(ds.order_count) AS avg_orders,
    ds.ca_state
FROM demographic_address_sales ds
JOIN customer_demographics cd ON ds.c_customer_sk = cd.cd_demo_sk
GROUP BY cd.cd_gender, ds.ca_state
ORDER BY total_revenue DESC, customer_count DESC;
