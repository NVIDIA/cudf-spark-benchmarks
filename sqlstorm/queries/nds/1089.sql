
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) as total_profit
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ss.ss_net_profit) > 10000
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(hvc.total_profit, 0) AS profit,
    CASE 
        WHEN cd.gender_rank <= 5 THEN 'Top Buyer'
        ELSE 'Regular Buyer'
    END AS customer_status
FROM 
    customer_data cd
LEFT JOIN 
    high_value_customers hvc ON cd.c_customer_sk = hvc.c_customer_sk
WHERE 
    cd.cd_purchase_estimate IS NOT NULL
ORDER BY 
    profit DESC, 
    cd.c_last_name ASC;
