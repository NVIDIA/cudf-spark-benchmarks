
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
ProductSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_qty,
        SUM(ws_ext_sales_price) AS total_sold_amt
    FROM web_sales
    GROUP BY ws_item_sk
),
ReturnRates AS (
    SELECT
        cr.sr_customer_sk,
        COALESCE(pr.total_sold_qty, 0) AS total_sales_qty,
        cr.total_return_qty,
        cr.total_return_amt,
        CASE 
            WHEN COALESCE(pr.total_sold_qty, 0) = 0 THEN NULL
            ELSE ROUND((cr.total_return_qty / NULLIF(pr.total_sold_qty, 0)) * 100, 2)
        END AS return_rate
    FROM CustomerReturns cr
    LEFT JOIN ProductSales pr ON cr.sr_customer_sk = pr.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    r.return_rate,
    r.total_return_qty,
    r.total_return_amt,
    CASE 
        WHEN r.return_rate IS NULL OR r.return_rate > 50 THEN 'High Return'
        WHEN r.return_rate BETWEEN 20 AND 50 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_class
FROM ReturnRates r
JOIN customer c ON r.sr_customer_sk = c.c_customer_sk
WHERE r.return_rate IS NOT NULL
ORDER BY r.return_rate DESC
LIMIT 100;
