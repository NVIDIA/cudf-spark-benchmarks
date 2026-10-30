
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_city, ca.ca_state
),
ranked_customers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        total_orders,
        total_spent,
        RANK() OVER (PARTITION BY cd_marital_status ORDER BY total_spent DESC) AS spender_rank
    FROM 
        customer_info
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    total_orders,
    total_spent,
    spender_rank
FROM 
    ranked_customers
WHERE 
    spender_rank <= 10
ORDER BY 
    cd_marital_status, total_spent DESC;
