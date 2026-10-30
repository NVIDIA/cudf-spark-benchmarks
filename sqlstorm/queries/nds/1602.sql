
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FullCustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(ws.total_sales, 0) AS total_sales,
        COALESCE(ws.order_count, 0) AS order_count 
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT
    fcs.c_customer_sk,
    fcs.c_first_name || ' ' || fcs.c_last_name AS full_name,
    fcs.return_count,
    fcs.total_return_amt,
    fcs.total_sales,
    fcs.order_count,
    CASE 
        WHEN fcs.return_count = 0 THEN 'No Returns'
        WHEN fcs.total_sales > fcs.total_return_amt THEN 'Healthy Customer'
        WHEN fcs.return_count > 5 THEN 'Frequent Returns'
        ELSE 'Consider Monitoring'
    END AS customer_status,
    RANK() OVER (ORDER BY fcs.total_sales DESC) AS sales_rank
FROM FullCustomerStats fcs
WHERE fcs.return_count >= 1 OR fcs.total_sales >= 1000
ORDER BY customer_status, fcs.total_sales DESC;
