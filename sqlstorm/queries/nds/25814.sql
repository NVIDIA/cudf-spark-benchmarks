
WITH base_data AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
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
        AND ca.ca_state IN ('NY', 'CA')
        AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
),
ranked_data AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_state ORDER BY total_spent DESC) AS rank_by_spending
    FROM 
        base_data
)
SELECT 
    c_customer_id,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_spent
FROM 
    ranked_data
WHERE 
    rank_by_spending <= 5
ORDER BY 
    ca_state, total_spent DESC;
