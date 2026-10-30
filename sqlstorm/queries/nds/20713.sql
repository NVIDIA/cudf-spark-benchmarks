
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year IN (2022, 2023) AND d_dow IN (1, 5) 
        )
    GROUP BY 
        sr_item_sk
)
SELECT 
    COALESCE(RS.ws_item_sk, HR.sr_item_sk) AS item_sk,
    RS.total_quantity,
    RS.total_sales,
    HR.total_return_quantity,
    HR.total_return_amt,
    COALESCE(RS.total_sales - HR.total_return_amt, RS.total_sales) AS net_sales,
    CASE 
        WHEN HR.total_return_amt IS NULL THEN 'No Returns'
        WHEN HR.total_return_amt >= 500 THEN 'High Returns'
        WHEN HR.total_return_amt IS NULL AND RS.total_sales > 1000 THEN 'Potential High Value Item'
        ELSE 'Normal Returns'
    END AS return_classification
FROM 
    RankedSales RS
FULL OUTER JOIN 
    HighValueReturns HR ON RS.ws_item_sk = HR.sr_item_sk
WHERE 
    COALESCE(RS.total_sales, 0) + COALESCE(HR.total_return_amt, 0) > 100
ORDER BY 
    net_sales DESC
LIMIT 100;
