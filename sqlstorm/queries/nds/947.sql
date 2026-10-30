
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT * 
    FROM CustomerStats 
    WHERE total_orders > 5 
    AND total_spent IS NOT NULL
),
AddressStats AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cs.ss_net_profit, 0)) AS total_profit
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    ab.ca_city,
    ab.ca_state,
    ab.customer_count,
    ab.total_profit,
    CASE 
        WHEN ab.customer_count > 50 THEN 'High Density' 
        WHEN ab.customer_count BETWEEN 10 AND 50 THEN 'Medium Density' 
        ELSE 'Low Density' 
    END AS address_density,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name
FROM 
    TopCustomers tc
JOIN 
    AddressStats ab ON ab.customer_count > 0
ORDER BY 
    total_spent DESC
LIMIT 100;
