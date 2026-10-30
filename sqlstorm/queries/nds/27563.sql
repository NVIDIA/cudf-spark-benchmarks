
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_full_name,
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
recent_sales AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_bench AS (
    SELECT 
        ci.customer_full_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_education_status, 
        ci.ca_city, 
        ci.ca_state, 
        COALESCE(rs.total_spent, 0) AS total_spent,
        COALESCE(rs.total_orders, 0) AS total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        recent_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    customer_full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    total_spent,
    total_orders,
    CAST(total_spent AS DECIMAL(10, 2)) / NULLIF(total_orders, 0) AS average_spent_per_order
FROM 
    customer_bench
ORDER BY 
    average_spent_per_order DESC
LIMIT 100;
