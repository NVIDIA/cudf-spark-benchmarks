
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
gender_sales AS (
    SELECT 
        ci.cd_gender,
        SUM(ss.total_sales) AS total_sales_by_gender,
        SUM(ss.order_count) AS total_orders
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
    GROUP BY 
        ci.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.total_sales_by_gender,
    gs.total_orders,
    CASE 
        WHEN gs.total_sales_by_gender > 10000 THEN 'High Value'
        WHEN gs.total_sales_by_gender BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    gender_sales gs
ORDER BY 
    gs.cd_gender;
