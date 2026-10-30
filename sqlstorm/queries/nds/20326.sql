
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        COALESCE(SUM(cs.cs_quantity) OVER (PARTITION BY ws.ws_item_sk), 0) AS total_catalog_quantity,
        CASE 
            WHEN SUM(cs.cs_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) IS NULL 
            THEN 'N/A' 
            ELSE CAST(SUM(cs.cs_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS STRING)
        END AS total_catalog_sales
    FROM 
        web_sales AS ws
    LEFT JOIN 
        catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date = DATE '2002-10-01' - INTERVAL '1 day'
        )
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < EXTRACT(YEAR FROM DATE '2002-10-01') - 30
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    rs.ws_item_sk,
    SUM(rs.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT rs.ws_order_number) AS order_count,
    MAX(rs.total_catalog_sales) AS max_catalog_sales,
    CASE WHEN COUNT(DISTINCT rs.ws_order_number) = 0 
        THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status
FROM 
    ranked_sales AS rs
RIGHT JOIN 
    customer_info AS ci ON rs.ws_item_sk IN (
        SELECT DISTINCT ws_item_sk 
        FROM web_sales 
        WHERE ws_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date <= DATE '2002-10-01' - INTERVAL '7 day'
        ) AND (
            SELECT MIN(d_date_sk) 
            FROM date_dim 
            WHERE d_date >= DATE '2002-10-01' - INTERVAL '30 day'
        )
    )
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, rs.ws_item_sk, ci.gender_rank
HAVING 
    SUM(rs.ws_net_profit) IS NOT NULL
ORDER BY 
    total_net_profit DESC, ci.gender_rank
LIMIT 50;
