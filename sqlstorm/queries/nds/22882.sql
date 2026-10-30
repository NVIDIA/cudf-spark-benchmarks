
WITH  SalesHierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.ss_sold_date_sk,
        SUM(cs.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(cs.ss_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cs.ss_sold_date_sk
),
MaxProfit AS (
    SELECT 
        sh.c_customer_id,
        MAX(sh.total_profit) AS max_profit
    FROM 
        SalesHierarchy sh
    WHERE 
        sh.profit_rank = 1
    GROUP BY 
        sh.c_customer_id
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY ca.ca_state) AS country_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
)
SELECT 
    sh.c_customer_id,
    sh.c_first_name,
    sh.c_last_name,
    mp.max_profit,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    SalesHierarchy sh
JOIN 
    MaxProfit mp ON sh.c_customer_id = mp.c_customer_id
LEFT JOIN 
    CustomerAddress ca ON sh.c_customer_id = ca.ca_address_id
WHERE 
    ca.country_rank <= (SELECT COUNT(*) FROM CustomerAddress WHERE ca_country = ca.ca_country) / 2
OR 
    mp.max_profit IS NULL
ORDER BY 
    sh.c_customer_id,
    sh.c_last_name DESC;
