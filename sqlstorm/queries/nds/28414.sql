
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, full_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, ca.ca_country
),
CustomerStats AS (
    SELECT 
        cd.*,
        CASE 
            WHEN total_orders = 0 THEN 'No Orders'
            WHEN total_spent < 100 THEN 'Low Spend'
            WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Spend'
            ELSE 'High Spend'
        END AS spend_category
    FROM 
        CustomerDetails cd
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    spend_category,
    total_orders,
    total_spent
FROM 
    CustomerStats
WHERE 
    cd_gender = 'M' 
    AND spend_category != 'No Orders'
ORDER BY 
    total_spent DESC
LIMIT 100;
