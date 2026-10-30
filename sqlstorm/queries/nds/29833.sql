
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        date_dim.d_date AS sold_date
    FROM 
        web_sales ws
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        date_dim.d_year = 2023
),
address_counts AS (
    SELECT 
        ci.full_address,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count
    FROM 
        customer_info ci
    GROUP BY 
        ci.full_address
)
SELECT 
    ac.full_address,
    ac.customer_count,
    COALESCE(SUM(sd.ws_quantity), 0) AS total_quantity,
    COALESCE(SUM(sd.ws_net_paid), 0) AS total_revenue
FROM 
    address_counts ac
LEFT JOIN 
    sales_data sd ON ac.customer_count > 0
GROUP BY 
    ac.full_address, 
    ac.customer_count
ORDER BY 
    total_revenue DESC, 
    ac.customer_count DESC
LIMIT 10;
