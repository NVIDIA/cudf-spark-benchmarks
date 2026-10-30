
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
recent_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq >= 10)
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(rs.total_spent, 0) AS total_spent,
    COALESCE(rs.order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(rs.order_count, 0) = 0 THEN 'No Orders'
        ELSE 'Orders Made'
    END AS order_status
FROM 
    customer_info ci
LEFT JOIN 
    recent_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    ci.ca_state = 'CA' AND ci.cd_gender = 'F'
ORDER BY 
    ci.full_name;
