
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 AND ws_quantity IS NOT NULL
),
TopSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        price_rank = 1
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        AVG(wr_return_amt) AS avg_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ts.ws_item_sk,
        ts.ws_sales_price,
        ts.ws_quantity,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.avg_return_amt, 0) AS avg_return_amt
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.wr_item_sk
),
FinalAnalysis AS (
    SELECT 
        sr.ws_item_sk,
        sr.ws_sales_price,
        SUM(sr.ws_quantity) AS total_sales_quantity,
        SUM(sr.total_returns) AS total_returns,
        COUNT(*) OVER () AS total_records,
        CASE 
            WHEN SUM(sr.ws_quantity) IS NULL OR SUM(sr.ws_quantity) = 0 THEN 'No Sales'
            ELSE 'Sales Exist'
        END AS sales_status
    FROM 
        SalesAndReturns sr
    GROUP BY 
        sr.ws_item_sk, sr.ws_sales_price
    HAVING 
        SUM(sr.ws_quantity) > 10 AND SUM(sr.total_returns) < 5
)
SELECT 
    f.sales_status,
    f.total_records,
    COALESCE(SUM(f.total_sales_quantity) / NULLIF(SUM(f.total_returns), 0), 0) AS sales_to_return_ratio
FROM 
    FinalAnalysis f
WHERE 
    f.total_records > 0
GROUP BY 
    f.sales_status, f.total_records
ORDER BY 
    f.total_records DESC;
