
WITH  sales_performance AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_profit) > 0
), 
customer_segment AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN cd.cd_demo_sk IS NOT NULL THEN cd.cd_demo_sk END) AS demographics_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COALESCE(AVG(hd.hd_dep_count), 0) AS avg_dependencies
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        sales_performance cs ON cs.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales) 
    WHERE 
        c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_net_profit > 0)
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cs.demographics_count,
    cu.total_quantity,
    cu.total_profit,
    cu.customer_rank,
    CASE 
        WHEN cs.avg_dependencies > 3 THEN 'High Dependency'
        WHEN cs.avg_dependencies BETWEEN 1 AND 3 THEN 'Medium Dependency'
        ELSE 'Low Dependency'
    END AS dependency_level
FROM 
    top_customers cu
JOIN 
    customer_segment cs ON cu.c_customer_sk = cs.c_customer_sk
WHERE 
    cu.customer_rank <= 10
ORDER BY 
    cu.total_profit DESC 
LIMIT 50;
