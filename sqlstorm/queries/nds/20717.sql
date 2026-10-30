
WITH customer_stats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_paid) AS avg_payment,
        NTILE(5) OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_band
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.cd_demo_sk,
        cs.cd_gender,
        cs.unique_customers,
        cs.total_profit,
        cs.avg_payment
    FROM 
        customer_stats cs
    WHERE 
        cs.profit_band = 1
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(tc.total_profit), 0) AS total_profit_by_location,
    COUNT(DISTINCT tc.cd_demo_sk) AS customer_count
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    top_customers tc ON c.c_current_cdemo_sk = tc.cd_demo_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_profit_by_location DESC,
    customer_count DESC
LIMIT 10;
