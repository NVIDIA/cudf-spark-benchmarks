WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_item_sk
),
HighValueItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        CASE 
            WHEN r.total_sales IS NULL THEN 'Unknown'
            WHEN r.total_sales < 1000 THEN 'Low Value'
            WHEN r.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS value_category
    FROM RankedSales r
    WHERE r.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        coalesce(SUM(sr_return_quantity), 0) AS total_returns,
        sr_item_sk
    FROM store_returns sr
    LEFT JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NULL
    GROUP BY sr_item_sk
)
SELECT 
    hi.ws_item_sk,
    hi.total_sales,
    hi.value_category,
    COALESCE(cr.total_returns, 0) AS total_returns
FROM HighValueItems hi
LEFT JOIN CustomerReturns cr ON hi.ws_item_sk = cr.sr_item_sk
WHERE hi.value_category <> 'Low Value'
ORDER BY hi.total_sales DESC, hi.ws_item_sk DESC;