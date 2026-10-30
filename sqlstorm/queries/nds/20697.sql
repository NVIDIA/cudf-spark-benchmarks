
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451000 AND 2451600
    GROUP BY ws_item_sk
),
FilteredStores AS (
    SELECT 
        DISTINCT s_store_sk,
        s_store_name,
        COALESCE(NULLIF(s_tax_precentage, 0), 0.01) AS effective_tax_percentage
    FROM store
    WHERE s_market_id IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
    HAVING COUNT(DISTINCT sr_ticket_number) > 5
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_returns,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_spent
    FROM CustomerReturns cr
    LEFT JOIN web_sales ws ON cr.sr_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cr.sr_customer_sk, cr.return_count, cr.total_returns
    HAVING COALESCE(SUM(ws.ws_sales_price), 0) > 500
)
SELECT 
    s.s_store_name,
    f.total_quantity,
    f.total_sales,
    rc.return_count,
    rc.total_returns,
    ROUND(f.total_sales * s.effective_tax_percentage / 100, 2) AS tax_amount,
    CASE 
        WHEN rc.return_count IS NULL THEN 'No Returns'
        WHEN rc.return_count = 0 THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status
FROM FilteredStores s
JOIN RankedSales f ON f.ws_item_sk IN (SELECT ws_item_sk FROM web_sales)
LEFT JOIN HighReturnCustomers rc ON rc.sr_customer_sk = s.s_store_sk
WHERE f.sales_rank <= 5
ORDER BY s.s_store_name, f.total_sales DESC;
