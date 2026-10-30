
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
), ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer_data
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_orders,
    rc.total_spent,
    CASE 
        WHEN rc.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Active Customer'
    END AS customer_status,
    COALESCE(ca.ca_city, 'Unknown') AS customer_city
FROM 
    ranked_customers rc
LEFT JOIN 
    customer_address ca ON rc.c_customer_sk = ca.ca_address_sk
WHERE 
    rc.spending_rank <= 10
ORDER BY 
    rc.cd_gender, rc.total_spent DESC;
