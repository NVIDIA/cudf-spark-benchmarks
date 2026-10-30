
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year < 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    COALESCE(SUM(sh.total_profit), 0) AS total_profit,
    ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY COALESCE(SUM(sh.total_profit), 0) DESC) AS rank,
    CONCAT(sh.c_first_name, ' ', sh.c_last_name) AS full_name
FROM 
    sales_hierarchy sh 
LEFT JOIN 
    customer_demographics cd ON sh.c_customer_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M')
    OR 
    (cd.cd_gender = 'M' AND cd.cd_credit_rating = 'Good')
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name
HAVING 
    COALESCE(SUM(sh.total_profit), 0) > 1000
ORDER BY 
    total_profit DESC
LIMIT 10;
