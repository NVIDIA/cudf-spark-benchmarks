
WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_sales_price) AS total_sales, 
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
StoreWithReturns AS (
    SELECT 
        sr_store_sk, 
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
StoreDetails AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        COALESCE(ss.total_sales, 0) AS total_sales, 
        COALESCE(sr.total_returns, 0) AS total_returns
    FROM 
        store s
    LEFT JOIN RankedSales ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN StoreWithReturns sr ON s.s_store_sk = sr.sr_store_sk
)
SELECT 
    sd.s_store_name, 
    sd.total_sales, 
    sd.total_returns, 
    CASE 
        WHEN sd.total_returns = 0 OR sd.total_sales = 0 THEN NULL
        ELSE (sd.total_returns * 1.0 / sd.total_sales) * 100
    END AS return_rate_percentage
FROM 
    StoreDetails sd
WHERE 
    (sd.total_sales > 1000 OR sd.total_returns IS NULL)
    AND (sd.total_sales IS NOT NULL OR sd.total_returns > 0)
ORDER BY 
    return_rate_percentage DESC NULLS LAST;
