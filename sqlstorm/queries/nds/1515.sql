
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_returned_date_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM store_returns
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1999
    GROUP BY c.c_customer_sk
),
TotalReturns AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returned
    FROM RankedReturns rr
    WHERE rr.rn = 1
    GROUP BY rr.sr_item_sk
),
SalesReturnsSummary AS (
    SELECT 
        cp.c_customer_sk,
        SUM(tr.total_returned) AS total_returns,
        COUNT(DISTINCT cp.purchase_count) AS unique_purchases
    FROM CustomerPurchases cp
    LEFT JOIN TotalReturns tr ON cp.c_customer_sk = tr.sr_item_sk
    GROUP BY cp.c_customer_sk
)
SELECT 
    cs.c_customer_sk AS c_customer_id,
    cs.total_sales,
    cs.total_quantity,
    COALESCE(srs.total_returns, 0) AS total_returns,
    COALESCE(srs.unique_purchases, 0) AS unique_purchases,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CustomerPurchases cs
LEFT JOIN SalesReturnsSummary srs ON cs.c_customer_sk = srs.c_customer_sk
WHERE cs.total_quantity > 0
ORDER BY cs.total_sales DESC;
