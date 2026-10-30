
WITH  sales_cte AS (
    SELECT 
        ss_sold_date_sk, 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_store_sk
),
top_stores AS (
    SELECT
        ss_store_sk,
        SUM(total_net_profit) AS cumulative_profit
    FROM 
        sales_cte
    WHERE 
        profit_rank <= 10
    GROUP BY 
        ss_store_sk
),
store_info AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        s_city, 
        s_state, 
        s_country, 
        CONCAT(s_store_name, ' - ', s_city, ', ', s_state) AS full_address
    FROM 
        store
),
total_sales AS (
    SELECT 
        COALESCE(ss.ss_store_sk, cs.cs_store_sk) AS store_sk,
        COALESCE(ss.total_sales, 0) AS total_store_sales,
        COALESCE(cs.total_sales, 0) AS total_catalog_sales
    FROM 
        (SELECT 
            ss_store_sk, 
            SUM(ss_net_paid) AS total_sales
         FROM 
            store_sales 
         GROUP BY ss_store_sk) ss
    FULL OUTER JOIN 
        (SELECT 
            cs_warehouse_sk AS cs_store_sk,
            SUM(cs_net_paid) AS total_sales
         FROM 
            catalog_sales 
         GROUP BY cs_warehouse_sk) cs
    ON ss.ss_store_sk = cs.cs_store_sk
)

SELECT 
    si.s_store_name,
    si.full_address,
    ts.cumulative_profit,
    COALESCE(ts.cumulative_profit, 0) AS adjusted_profit,
    CASE 
        WHEN COALESCE(ts.cumulative_profit, 0) > 10000 THEN 'High Performer'
        WHEN COALESCE(ts.cumulative_profit, 0) BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Needs Improvement' 
    END AS performance_category,
    ROW_NUMBER() OVER (ORDER BY ts.cumulative_profit DESC) AS store_rank
FROM 
    store_info si
LEFT JOIN 
    top_stores ts ON si.s_store_sk = ts.ss_store_sk
WHERE 
    si.s_state = 'CA'
ORDER BY 
    ts.cumulative_profit DESC NULLS LAST
LIMIT 20;
