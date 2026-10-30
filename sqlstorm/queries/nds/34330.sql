
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CD.cd_demo_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, CD.cd_demo_sk
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
address_ranking AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        RANK() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS city_rank
    FROM 
        customer_address AS ca 
    LEFT JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    a.ca_city,
    a.ca_state,
    sh.total_quantity,
    sh.total_profit,
    CASE 
        WHEN city_rank = 1 THEN 'Top City'
        WHEN city_rank <= 5 THEN 'Top 5 City'
        ELSE 'Others' 
    END AS city_category
FROM 
    sales_hierarchy AS sh
JOIN 
    customer AS c ON sh.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    address_ranking AS ar ON a.ca_address_sk = ar.ca_address_sk
WHERE 
    sh.rnk = 1
ORDER BY 
    total_profit DESC, city_category;
