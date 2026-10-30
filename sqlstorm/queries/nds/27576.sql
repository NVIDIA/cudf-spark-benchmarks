WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) AS average_age
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, full_name, ca.ca_city, cd.cd_gender
)

SELECT 
    cs.full_name,
    cs.ca_city,
    cs.cd_gender,
    cs.total_orders,
    cs.total_profit,
    CASE 
        WHEN cs.total_orders > 5 THEN 'Frequent'
        ELSE 'Infrequent'
    END AS customer_type,
    CASE 
        WHEN cs.average_age < 30 THEN 'Young'
        WHEN cs.average_age BETWEEN 30 AND 50 THEN 'Middle-aged'
        ELSE 'Senior'
    END AS age_group
FROM 
    customer_stats cs
WHERE 
    cs.total_profit > 1000
ORDER BY 
    cs.total_profit DESC;