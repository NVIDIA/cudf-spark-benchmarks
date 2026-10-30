
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
date_info AS (
    SELECT 
        d.d_date_sk, 
        d.d_date, 
        d.d_day_name, 
        d.d_month_seq, 
        d.d_year
    FROM 
        date_dim d
), 
purchase_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
), 
customer_purchases AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        pi.total_sales,
        pi.order_count,
        di.d_year,
        di.d_month_seq
    FROM 
        customer_info ci
    LEFT JOIN 
        purchase_info pi ON ci.c_customer_sk = pi.ws_bill_customer_sk
    LEFT JOIN 
        date_info di ON di.d_year BETWEEN 2020 AND 2023
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COALESCE(total_sales, 0) AS total_spent,
    COALESCE(order_count, 0) AS num_orders,
    COUNT(DISTINCT d_month_seq) AS active_months
FROM 
    customer_purchases
GROUP BY 
    full_name, ca_city, ca_state, total_sales, order_count
ORDER BY 
    total_spent DESC
LIMIT 100;
