
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE 
                WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_net_paid 
                ELSE 0 
            END) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
customer_performance AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.total_spent,
        rc.total_orders,
        RANK() OVER (ORDER BY rc.total_spent DESC) AS spending_rank
    FROM 
        ranked_customers rc
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.cd_education_status,
    cp.total_spent,
    cp.total_orders,
    cp.spending_rank,
    a.ca_city,
    a.ca_state,
    a.ca_country
FROM 
    customer_performance cp
JOIN 
    customer_address a ON cp.c_customer_sk = a.ca_address_sk
WHERE 
    cp.total_orders > 5
ORDER BY 
    cp.spending_rank
LIMIT 50;
