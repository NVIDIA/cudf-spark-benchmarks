
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM date_dim d
    WHERE d.d_year BETWEEN 2020 AND 2023
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS orders_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        di.d_year,
        di.d_month_seq,
        di.d_day_name,
        si.total_sales,
        si.orders_count
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN date_info di ON si.ws_bill_customer_sk IS NOT NULL
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) OVER (PARTITION BY d_year, d_month_seq) AS monthly_customer_count,
    AVG(total_sales) OVER (PARTITION BY d_year, d_month_seq) AS avg_sales_per_month,
    SUM(orders_count) AS total_orders,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM combined_info
GROUP BY 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    d_year,
    d_month_seq,
    total_sales,
    orders_count
ORDER BY d_year, d_month_seq, full_name;
