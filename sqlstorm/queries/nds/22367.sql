
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_sold_date_sk, ss_item_sk
), ReturnStats AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_store_sk
), FinalStats AS (
    SELECT 
        s.s_store_id,
        COALESCE(r.total_quantity, 0) AS items_sold,
        COALESCE(r.total_sales, 0) AS sales_amount,
        COALESCE(rs.total_returns, 0) AS returns,
        COALESCE(rs.total_return_amt, 0) AS return_amount,
        CASE 
            WHEN COALESCE(r.total_sales, 0) > 0 THEN (COALESCE(rs.total_return_amt, 0) / COALESCE(r.total_sales, 0)) * 100 
            ELSE NULL 
        END AS return_rate,
        CASE 
            WHEN rs.total_returns IS NOT NULL AND rs.total_returns > 0 THEN 'High Return'
            WHEN rs.total_returns IS NULL THEN 'No Return Info'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        (SELECT s_store_sk, s_store_id FROM store) s
    LEFT JOIN (
        SELECT 
            ss_store_sk,
            SUM(ss_quantity) AS total_quantity,
            SUM(ss_net_paid) AS total_sales
        FROM 
            store_sales
        GROUP BY 
            ss_store_sk
    ) r ON s.s_store_sk = r.ss_store_sk
    LEFT JOIN ReturnStats rs ON s.s_store_sk = rs.sr_store_sk
)
SELECT 
    f.s_store_id,
    f.items_sold,
    f.sales_amount,
    f.returns,
    f.return_amount,
    f.return_rate,
    f.return_category
FROM 
    FinalStats f
WHERE 
    f.items_sold > 0
ORDER BY 
    f.sales_amount DESC NULLS LAST
LIMIT 10;
