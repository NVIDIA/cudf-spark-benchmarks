
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_customer_sk
), SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), FinalReport AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_discount, 0) AS total_discount,
        COALESCE(ss.order_count, 0) AS order_count,
        CASE
            WHEN COALESCE(ss.total_sales, 0) > 0 THEN (COALESCE(cr.total_return_amount, 0) / COALESCE(ss.total_sales, 0)) * 100
            ELSE 0
        END AS return_percentage
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.customer_sk
)
SELECT 
    c.c_customer_id,
    f.total_returns,
    f.total_return_amount,
    f.total_return_tax,
    f.total_sales,
    f.total_discount,
    f.order_count,
    f.return_percentage
FROM FinalReport f
JOIN customer c ON f.c_customer_id = c.c_customer_id
WHERE f.return_percentage > 0
ORDER BY f.return_percentage DESC
LIMIT 100;
