
WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        ss_sold_date_sk, 
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        ss_store_sk, 
        ss_sold_date_sk
), 
CustomerReturns AS (
    SELECT 
        sr_store_sk, 
        COUNT(*) AS return_count, 
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
StorePerformance AS (
    SELECT 
        R.ss_store_sk,
        R.ss_sold_date_sk,
        R.total_sales,
        COALESCE(C.return_count, 0) AS return_count,
        COALESCE(C.total_returns, 0) AS total_returns,
        (R.total_sales - COALESCE(C.total_returns, 0)) AS net_sales,
        CASE
            WHEN R.total_sales = 0 THEN 0
            ELSE (COALESCE(C.total_returns, 0) / R.total_sales) * 100
        END AS return_rate
    FROM 
        RankedSales R
    LEFT JOIN 
        CustomerReturns C ON R.ss_store_sk = C.sr_store_sk
)
SELECT 
    SP.ss_store_sk,
    SP.ss_sold_date_sk,
    SP.total_sales,
    SP.return_count,
    SP.total_returns,
    SP.net_sales,
    SP.return_rate
FROM 
    StorePerformance SP
JOIN 
    store S ON SP.ss_store_sk = S.s_store_sk
WHERE 
    S.s_state = 'CA' 
    AND SP.return_rate < 5
ORDER BY 
    SP.net_sales DESC
LIMIT 10;
