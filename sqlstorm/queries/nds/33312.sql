
WITH  sales_hierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales 
    GROUP BY 
        ss_store_sk
), 
returns_data AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_store_sk
), 
sales_returns AS (
    SELECT 
        sh.ss_store_sk,
        sh.total_profit,
        sh.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        (sh.total_profit - COALESCE(rd.total_return_amt, 0)) AS net_profit_after_returns
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        returns_data rd ON sh.ss_store_sk = rd.sr_store_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    sr.total_profit,
    sr.total_sales,
    sr.total_returns,
    sr.total_return_amt,
    sr.net_profit_after_returns,
    CASE 
        WHEN sr.total_sales > 0 THEN (sr.total_profit / sr.total_sales) 
        ELSE NULL 
    END AS average_profit_per_sale
FROM 
    sales_returns sr
JOIN 
    store s ON sr.ss_store_sk = s.s_store_sk
WHERE 
    sr.net_profit_after_returns > 0
ORDER BY 
    sr.net_profit_after_returns DESC
LIMIT 10;

