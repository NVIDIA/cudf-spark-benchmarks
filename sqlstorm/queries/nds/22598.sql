
WITH  address_cost AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        SUM(CASE 
            WHEN c.c_current_cdemo_sk IS NOT NULL THEN 1 
            ELSE 0 
        END) AS customer_count,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        ca_address_sk, ca_city, ca_state, ca_country
),
demographic_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    ac.ca_country,
    ac.customer_count,
    ac.total_orders,
    ac.total_spent,
    ds.avg_purchase_estimate,
    ds.demographic_count,
    CASE 
        WHEN ac.total_spent IS NULL THEN 'No Spend'
        WHEN ac.total_spent > 1000 THEN 'High Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    address_cost ac
LEFT JOIN 
    (SELECT 
         cd_gender,
         cd_marital_status, 
         MIN(avg_purchase_estimate) AS avg_purchase_estimate, 
         COUNT(demographic_count) AS demographic_count
     FROM 
         demographic_summary 
     GROUP BY 
         cd_gender, cd_marital_status) ds ON ds.cd_gender = (
           CASE 
               WHEN ac.customer_count > 50 THEN 'M'
               WHEN ac.customer_count BETWEEN 20 AND 50 THEN 'F'
               ELSE NULL
           END)
ORDER BY 
    ac.total_spent DESC NULLS LAST
LIMIT 100 OFFSET 0;
