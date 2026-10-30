
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        total_purchases,
        total_spent
    FROM 
        customer_stats c
    WHERE 
        purchase_rank <= 5
),
addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    tc.c_customer_sk,
    tc.total_purchases,
    tc.total_spent,
    a.ca_city,
    a.ca_state,
    a.address_count,
    CASE 
        WHEN a.address_count > 1 THEN 'Multiple Addresses'
        ELSE 'Single Address'
    END AS address_type
FROM 
    top_customers tc
JOIN 
    addresses a ON tc.c_customer_sk = a.ca_address_sk
ORDER BY 
    tc.total_spent DESC;
