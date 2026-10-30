
WITH processed_data AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_city IS NOT NULL 
        AND ca.ca_state IS NOT NULL
        AND c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        full_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_sales,
    total_revenue,
    CASE 
        WHEN total_revenue < 1000 THEN 'Low Spender'
        WHEN total_revenue BETWEEN 1000 AND 5000 THEN 'Moderate Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    processed_data
WHERE 
    total_sales > 5
ORDER BY 
    total_revenue DESC;
