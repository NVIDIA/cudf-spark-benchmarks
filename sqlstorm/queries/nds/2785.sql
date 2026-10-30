
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        COUNT(DISTINCT ws.web_site_sk) AS web_site_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_site ws ON c.c_customer_sk = ws.web_site_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_city
)
SELECT 
    cd.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(rs.ws_quantity) AS total_quantity,
    AVG(rs.ws_net_profit) AS avg_net_profit,
    MIN(rs.ws_net_profit) AS min_net_profit,
    MAX(rs.ws_net_profit) AS max_net_profit,
    ARRAY_AGG(DISTINCT rs.ws_sold_date_sk) AS sold_dates
FROM 
    customer_details cd
JOIN 
    ranked_sales rs ON cd.c_customer_sk = rs.ws_item_sk
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
    AND cd.web_site_count > 0
    AND rs.rank_profit <= 5
GROUP BY 
    cd.ca_city, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_quantity DESC
LIMIT 100;
